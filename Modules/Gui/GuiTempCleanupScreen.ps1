# ============================================================
# GUI TEMP CLEANUP SCREEN
# ============================================================

function Set-GuiTempCleanupCheckboxState {
  # Same visual toggle pattern already used for the Applications screen's per-row checkbox (New-GuiApplicationRow), just applied to a fixed, statically-defined XAML checkbox instead of a dynamically built one.
  param(
    [Parameter(Mandatory)]
    [System.Windows.Controls.Border]$Checkbox,

    [Parameter(Mandatory)]
    [System.Windows.Shapes.Path]$Checkmark,

    [Parameter(Mandatory)]
    [bool]$IsChecked
  )

  if ($IsChecked) {
    $Checkbox.Background = "#38BDF8"
    $Checkbox.BorderThickness = "0"
    $Checkmark.Visibility = "Visible"
  }
  else {
    $Checkbox.Background = "Transparent"
    $Checkbox.BorderBrush = "#565A64"
    $Checkbox.BorderThickness = "1.5"
    $Checkmark.Visibility = "Collapsed"
  }
}

function Update-GuiTempCleanupCard {
  param(
    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$PathText,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$SummaryText,

    [Parameter(Mandatory)]
    [PSCustomObject]$Target
  )

  $PathText.Text = $Target.Path

  if ($Target.Accessible) {
    $SummaryText.Text = "$($Target.FileCount) file(s), $($Target.SizeText)"
    $SummaryText.Foreground = "#E8E9EC"
  }
  else {
    $SummaryText.Text = "Could not be scanned: $($Target.ErrorMessage)"
    $SummaryText.Foreground = "#F2555A"
  }
}

function Start-GuiTempCleanupScan {
  param(
    [Parameter(Mandatory)]
    [hashtable]$CardControls,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Button]$RefreshButton,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Button]$CleanButton
  )

  $RefreshButton.IsEnabled = $false
  $CleanButton.IsEnabled = $false

  foreach ($Name in $CardControls.Keys) {
    $CardControls[$Name].SummaryText.Text = "Scanning..."
    $CardControls[$Name].SummaryText.Foreground = "#E8E9EC"
  }

  $RootPath = $script:ITDeploymentToolRoot

  # Scanning Windows Temp/Prefetch can be slow and, on a non-elevated process, would throw -- running this off the UI thread mirrors the same background-runspace pattern already proven for Device Details and Deployment Validation.
  $BackgroundScript = {
    param([string]$RootPath)

    . (Join-Path $RootPath "Modules\Windows\TempCleanup.ps1")

    return @(Get-TempCleanupTargets)
  }

  $Runspace = [runspacefactory]::CreateRunspace()
  $Runspace.Open()

  $PowerShellInstance = [powershell]::Create()
  $PowerShellInstance.Runspace = $Runspace

  [void]$PowerShellInstance.AddScript($BackgroundScript)
  [void]$PowerShellInstance.AddArgument($RootPath)

  $AsyncResult = $PowerShellInstance.BeginInvoke()

  $script:GuiTempCleanupAsyncResult = $AsyncResult
  $script:GuiTempCleanupPowerShell = $PowerShellInstance
  $script:GuiTempCleanupRunspace = $Runspace
  $script:GuiTempCleanupCardControls = $CardControls
  $script:GuiTempCleanupRefreshButton = $RefreshButton
  $script:GuiTempCleanupCleanButton = $CleanButton

  $Timer = New-Object System.Windows.Threading.DispatcherTimer
  $Timer.Interval = [TimeSpan]::FromMilliseconds(200)
  $script:GuiTempCleanupTimer = $Timer

  # Plain scriptblock -- deliberately NOT .GetNewClosure()'d, matching every other background-runspace timer handler in this app.
  $Timer.Add_Tick({
    if (-not $script:GuiTempCleanupAsyncResult.IsCompleted) {
      return
    }

    $script:GuiTempCleanupTimer.Stop()

    try {
      $Targets = @($script:GuiTempCleanupPowerShell.EndInvoke($script:GuiTempCleanupAsyncResult))

      if ($script:GuiTempCleanupPowerShell.HadErrors) {
        foreach ($ScanError in $script:GuiTempCleanupPowerShell.Streams.Error) {
          Write-DeploymentLog -Message ([string]$ScanError) -Level "ERROR"
        }
      }

      $script:GuiTempCleanupTargets = @{}

      foreach ($Target in $Targets) {
        $script:GuiTempCleanupTargets[$Target.Name] = $Target

        if ($script:GuiTempCleanupCardControls.ContainsKey($Target.Name)) {
          Update-GuiTempCleanupCard -PathText $script:GuiTempCleanupCardControls[$Target.Name].PathText -SummaryText $script:GuiTempCleanupCardControls[$Target.Name].SummaryText -Target $Target
        }
      }
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Temp cleanup scan error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
    finally {
      $script:GuiTempCleanupPowerShell.Dispose()
      $script:GuiTempCleanupRunspace.Close()
      $script:GuiTempCleanupRunspace.Dispose()
      $script:GuiTempCleanupRefreshButton.IsEnabled = $true
      $script:GuiTempCleanupCleanButton.IsEnabled = $true
    }
  })

  $Timer.Start()
}

function Invoke-GuiTempCleanup {
  param(
    [Parameter(Mandatory)]
    [hashtable]$Selected,

    [Parameter(Mandatory)]
    [hashtable]$CardControls,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Button]$RefreshButton,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Button]$CleanButton,

    [Parameter(Mandatory)]
    [hashtable]$ModalControls
  )

  if ($null -eq $script:GuiTempCleanupTargets) {
    Show-GuiDialog -Title "Not Ready" -Icon Info -Message "Please wait for the scan to finish first."
    return
  }

  $TargetsToClean = @()

  foreach ($Name in $Selected.Keys) {
    if ($Selected[$Name] -and $script:GuiTempCleanupTargets.ContainsKey($Name)) {
      $TargetsToClean += $script:GuiTempCleanupTargets[$Name]
    }
  }

  if ($TargetsToClean.Count -eq 0) {
    Show-GuiDialog -Title "Nothing Selected" -Icon Info -Message "No locations selected."
    return
  }

  $TotalBytesSum = ($TargetsToClean | Measure-Object -Property TotalSizeBytes -Sum).Sum
  $TotalSizeText = Format-TempCleanupSize -Bytes $TotalBytesSum
  $NamesText = ($TargetsToClean | ForEach-Object { $_.Name }) -join ", "

  $Confirmation = Show-GuiDialog -Title "Clean Temp Files" -Icon Warning -Buttons YesNo `
    -Message "This will permanently delete files in: $NamesText ($TotalSizeText total). Continue?"

  if ($Confirmation -ne "Yes") {
    return
  }

  $RefreshButton.IsEnabled = $false
  $CleanButtonOriginalContent = $CleanButton.Content
  $CleanButton.IsEnabled = $false
  $CleanButton.Content = "Cleaning..."

  # Forces a Render-priority dispatch so "Cleaning..." actually paints before the slower synchronous deletion runs -- same technique Show-GuiScreenLoadingState already uses elsewhere in this app. Deletion itself stays synchronous (not a background runspace) since this is a single, already-confirmed, bounded action across exactly 3 possible locations, not an open-ended user-selected list.
  $CleanButton.Dispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Render)

  $Results = @($TargetsToClean | ForEach-Object { Remove-TempCleanupTarget -Target $_ })

  $CleanButton.Content = $CleanButtonOriginalContent
  $RefreshButton.IsEnabled = $true
  $CleanButton.IsEnabled = $true

  $CleanedCount = @($Results | Where-Object { $_.Status -eq "Cleaned" }).Count
  $FailedResults = @($Results | Where-Object { $_.Status -ne "Cleaned" })
  $FailedCount = $FailedResults.Count

  $Counts = [ordered]@{ Cleaned = $CleanedCount; Failed = $FailedCount }

  # Surfaces both real failures and partial success (some files skipped because they were locked) as details worth reading -- a fully clean location with nothing skipped doesn't need to clutter the details view.
  $DetailMessages = @($Results | Where-Object { ($_.Status -ne "Cleaned") -or ($_.SkippedCount -gt 0) } | ForEach-Object { $_.Message })

  Show-GuiCompletionModal -Overlay $ModalControls.Overlay -IconSuccess $ModalControls.IconSuccess -IconWarning $ModalControls.IconWarning `
    -TitleText $ModalControls.TitleText -CountsPanel $ModalControls.CountsPanel -DetailsCard $ModalControls.DetailsCard `
    -DetailsPanel $ModalControls.DetailsPanel -Title "Cleanup Complete" -Counts $Counts -FailureMessages $DetailMessages

  Start-GuiTempCleanupScan -CardControls $CardControls -RefreshButton $RefreshButton -CleanButton $CleanButton
}

function Initialize-GuiTempCleanupScreen {
  # FindName + click-handler wiring for this screen, called once from Show-MainWindow (GuiWindow.ps1). Returns the Nav Border/Text/Icon triple so the orchestrator can add this screen to the shared nav arrays.
  param(
    [Parameter(Mandatory)]
    [System.Windows.Window]$Window,

    [Parameter(Mandatory)]
    [hashtable]$CompletionModalControls
  )

  $RefreshTempCleanupButton = $Window.FindName("RefreshTempCleanupButton")
  $CleanSelectedTempButton = $Window.FindName("CleanSelectedTempButton")
  $TempCleanupUserTempCard = $Window.FindName("TempCleanupUserTempCard")
  $TempCleanupUserTempCheckbox = $Window.FindName("TempCleanupUserTempCheckbox")
  $TempCleanupUserTempCheckmark = $Window.FindName("TempCleanupUserTempCheckmark")
  $TempCleanupUserTempPathText = $Window.FindName("TempCleanupUserTempPathText")
  $TempCleanupUserTempSummaryText = $Window.FindName("TempCleanupUserTempSummaryText")
  $TempCleanupWindowsTempCard = $Window.FindName("TempCleanupWindowsTempCard")
  $TempCleanupWindowsTempCheckbox = $Window.FindName("TempCleanupWindowsTempCheckbox")
  $TempCleanupWindowsTempCheckmark = $Window.FindName("TempCleanupWindowsTempCheckmark")
  $TempCleanupWindowsTempPathText = $Window.FindName("TempCleanupWindowsTempPathText")
  $TempCleanupWindowsTempSummaryText = $Window.FindName("TempCleanupWindowsTempSummaryText")
  $TempCleanupPrefetchCard = $Window.FindName("TempCleanupPrefetchCard")
  $TempCleanupPrefetchCheckbox = $Window.FindName("TempCleanupPrefetchCheckbox")
  $TempCleanupPrefetchCheckmark = $Window.FindName("TempCleanupPrefetchCheckmark")
  $TempCleanupPrefetchPathText = $Window.FindName("TempCleanupPrefetchPathText")
  $TempCleanupPrefetchSummaryText = $Window.FindName("TempCleanupPrefetchSummaryText")
  $NavTempCleanup = $Window.FindName("NavTempCleanup")
  $NavTempCleanupText = $Window.FindName("NavTempCleanupText")
  $NavTempCleanupIcon = $Window.FindName("NavTempCleanupIcon")

  # Keyed by the same location Name used throughout TempCleanup.ps1 (Get-TempCleanupTargetPaths/Get-TempCleanupTargets), so scan results and checkbox state can be looked up by name instead of a chain of if/elseif per card.
  $TempCleanupCardControls = [ordered]@{
    "User Temp"    = @{ PathText = $TempCleanupUserTempPathText; SummaryText = $TempCleanupUserTempSummaryText }
    "Windows Temp" = @{ PathText = $TempCleanupWindowsTempPathText; SummaryText = $TempCleanupWindowsTempSummaryText }
    "Prefetch"     = @{ PathText = $TempCleanupPrefetchPathText; SummaryText = $TempCleanupPrefetchSummaryText }
  }

  # All three cards default to checked, matching Get-TempCleanupTargets always scanning all three locations regardless of selection.
  $script:GuiTempCleanupSelected = [ordered]@{
    "User Temp"    = $true
    "Windows Temp" = $true
    "Prefetch"     = $true
  }

  $script:GuiTempCleanupLoaded = $false
  $script:GuiTempCleanupToolbar = $Window.FindName("TempCleanupToolbar")
  $script:GuiTempCleanupScrollViewer = $Window.FindName("TempCleanupScrollViewer")
  $script:GuiTempCleanupCardControls = $TempCleanupCardControls
  $script:GuiRefreshTempCleanupButton = $RefreshTempCleanupButton
  $script:GuiCleanSelectedTempButton = $CleanSelectedTempButton

  $RefreshTempCleanupButton.Add_Click({
    try {
      Start-GuiTempCleanupScan -CardControls $TempCleanupCardControls -RefreshButton $RefreshTempCleanupButton -CleanButton $CleanSelectedTempButton
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Refresh error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $CleanSelectedTempButton.Add_Click({
    try {
      Invoke-GuiTempCleanup -Selected $script:GuiTempCleanupSelected -CardControls $TempCleanupCardControls -RefreshButton $RefreshTempCleanupButton -CleanButton $CleanSelectedTempButton -ModalControls $CompletionModalControls
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Temp cleanup error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $TempCleanupUserTempCard.Add_MouseLeftButtonUp({
    try {
      $script:GuiTempCleanupSelected["User Temp"] = -not $script:GuiTempCleanupSelected["User Temp"]
      Set-GuiTempCleanupCheckboxState -Checkbox $TempCleanupUserTempCheckbox -Checkmark $TempCleanupUserTempCheckmark -IsChecked $script:GuiTempCleanupSelected["User Temp"]
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Checkbox error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $TempCleanupWindowsTempCard.Add_MouseLeftButtonUp({
    try {
      $script:GuiTempCleanupSelected["Windows Temp"] = -not $script:GuiTempCleanupSelected["Windows Temp"]
      Set-GuiTempCleanupCheckboxState -Checkbox $TempCleanupWindowsTempCheckbox -Checkmark $TempCleanupWindowsTempCheckmark -IsChecked $script:GuiTempCleanupSelected["Windows Temp"]
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Checkbox error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $TempCleanupPrefetchCard.Add_MouseLeftButtonUp({
    try {
      $script:GuiTempCleanupSelected["Prefetch"] = -not $script:GuiTempCleanupSelected["Prefetch"]
      Set-GuiTempCleanupCheckboxState -Checkbox $TempCleanupPrefetchCheckbox -Checkmark $TempCleanupPrefetchCheckmark -IsChecked $script:GuiTempCleanupSelected["Prefetch"]
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Checkbox error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $NavTempCleanup.Add_MouseLeftButtonUp({
    try {
      Switch-GuiScreen -ScreenName "Temp Cleanup" -ActiveBorder $NavTempCleanup -ActiveText $NavTempCleanupText -ActiveIcon $NavTempCleanupIcon
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Navigation error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  return @{
    NavBorder = $NavTempCleanup
    NavText   = $NavTempCleanupText
    NavIcon   = $NavTempCleanupIcon
  }
}
