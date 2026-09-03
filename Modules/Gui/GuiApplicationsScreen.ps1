# ============================================================
# GUI APPLICATIONS SCREEN
# ============================================================
# Completion-modal reporting (Show-GuiCompletionModal/Get-GuiCompletionSummary/Invoke-GuiCopyCompletionSummary) moved to GuiCompletionModal.ps1, since it is shared with Temp Cleanup and is no longer Applications-specific.

function New-GuiApplicationRow {
  param(
    [Parameter(Mandatory)]
    [PSCustomObject]$Application
  )

  $RowGrid = New-Object System.Windows.Controls.Grid
  $RowGrid.Margin = "0,3,0,3"

  $NameColumn = New-Object System.Windows.Controls.ColumnDefinition
  $NameColumn.Width = "*"
  $RowGrid.ColumnDefinitions.Add($NameColumn)

  $RecommendedColumn = New-Object System.Windows.Controls.ColumnDefinition
  $RecommendedColumn.Width = "Auto"
  $RowGrid.ColumnDefinitions.Add($RecommendedColumn)

  $StatusColumn = New-Object System.Windows.Controls.ColumnDefinition
  $StatusColumn.Width = "Auto"
  $RowGrid.ColumnDefinitions.Add($StatusColumn)

  $RowPanel = New-Object System.Windows.Controls.StackPanel
  $RowPanel.Orientation = "Horizontal"
  $RowPanel.Cursor = "Hand"
  # A Panel with no Background is only hit-testable where its children actually paint pixels -- clicks in the gaps between the checkbox and the name text would otherwise fall through and never reach this row's click handler.
  $RowPanel.Background = "Transparent"

  $CheckboxMark = New-Object System.Windows.Shapes.Path
  $CheckboxMark.Stroke = "#0B1116"
  $CheckboxMark.StrokeThickness = 1.7
  $CheckboxMark.StrokeStartLineCap = "Round"
  $CheckboxMark.StrokeEndLineCap = "Round"
  $CheckboxMark.StrokeLineJoin = "Round"
  $CheckboxMark.Data = "M1.5 5L4 7.5L8.5 2"

  $CheckboxCanvas = New-Object System.Windows.Controls.Canvas
  $CheckboxCanvas.Width = 10
  $CheckboxCanvas.Height = 10
  $CheckboxCanvas.HorizontalAlignment = "Center"
  $CheckboxCanvas.VerticalAlignment = "Center"
  $CheckboxCanvas.Children.Add($CheckboxMark) | Out-Null

  $Checkbox = New-Object System.Windows.Controls.Border
  $Checkbox.Width = 16
  $Checkbox.Height = 16
  $Checkbox.CornerRadius = "4"
  $Checkbox.VerticalAlignment = "Center"
  $Checkbox.Child = $CheckboxCanvas

  if ([bool]$Application.Selected) {
    $Checkbox.Background = "#38BDF8"
  }
  else {
    # A Border with only BorderBrush/BorderThickness set (no Background) is only hit-testable on the painted stroke itself, not its interior -- the same gotcha already worked around on the title bar buttons. Without an explicit transparent Background here, clicking inside an unchecked box does nothing.
    $Checkbox.Background = "Transparent"
    $Checkbox.BorderBrush = "#565A64"
    $Checkbox.BorderThickness = "1.5"
    $CheckboxMark.Visibility = "Collapsed"
  }

  $RowPanel.Children.Add($Checkbox) | Out-Null

  $NameText = New-Object System.Windows.Controls.TextBlock
  $NameText.Text = $Application.Name
  $NameText.TextTrimming = "CharacterEllipsis"
  $NameText.Foreground = "#E8E9EC"
  $NameText.FontSize = 12.5
  $NameText.VerticalAlignment = "Center"
  $NameText.Margin = "9,0,0,0"
  $RowPanel.Children.Add($NameText) | Out-Null

  $RowPanel.Tag = $Application
  $RowPanel.Add_MouseLeftButtonUp({
    $App = $this.Tag
    $App.Selected = -not [bool]$App.Selected
    $CheckboxBorder = $this.Children[0]

    if ($App.Selected) {
      $CheckboxBorder.Background = "#38BDF8"
      $CheckboxBorder.BorderThickness = "0"
      $CheckboxBorder.Child.Children[0].Visibility = "Visible"
    }
    else {
      $CheckboxBorder.Background = "Transparent"
      $CheckboxBorder.BorderBrush = "#565A64"
      $CheckboxBorder.BorderThickness = "1.5"
      $CheckboxBorder.Child.Children[0].Visibility = "Collapsed"
    }

    Update-GuiSelectedCount -CountText $script:GuiSelectedCountText
  })

  [System.Windows.Controls.Grid]::SetColumn($RowPanel, 0)
  $RowGrid.Children.Add($RowPanel) | Out-Null

  if ($Application.Recommended -eq $true) {
    $RecommendedIcon = New-GuiRecommendedIcon
    $RecommendedIcon.Margin = "8,0,0,0"
    $RecommendedIcon.VerticalAlignment = "Center"
    [System.Windows.Controls.Grid]::SetColumn($RecommendedIcon, 1)
    $RowGrid.Children.Add($RecommendedIcon) | Out-Null
  }

  $StatusPanel = New-Object System.Windows.Controls.StackPanel
  $StatusPanel.Orientation = "Horizontal"
  $StatusPanel.VerticalAlignment = "Center"
  $StatusPanel.Margin = "8,0,0,0"

  $StatusColor = if ($Application.Installed) { "#34D399" } else { "#6B6F79" }
  $StatusDotColor = if ($Application.Installed) { "#34D399" } else { "#4A4E58" }

  $StatusDot = New-Object System.Windows.Shapes.Ellipse
  $StatusDot.Width = 5
  $StatusDot.Height = 5
  $StatusDot.Fill = $StatusDotColor
  $StatusDot.VerticalAlignment = "Center"
  $StatusDot.Margin = "0,0,5,0"
  $StatusPanel.Children.Add($StatusDot) | Out-Null

  $StatusText = New-Object System.Windows.Controls.TextBlock
  $StatusText.Text = if ($Application.Installed) { "Installed" } else { "Not Installed" }
  $StatusText.FontSize = 10.5
  $StatusText.FontWeight = if ($Application.Installed) { "SemiBold" } else { "Medium" }
  $StatusText.Foreground = $StatusColor
  $StatusPanel.Children.Add($StatusText) | Out-Null

  [System.Windows.Controls.Grid]::SetColumn($StatusPanel, 2)
  $RowGrid.Children.Add($StatusPanel) | Out-Null

  return $RowGrid
}

function New-GuiCategoryCard {
  param(
    [Parameter(Mandatory)]
    [string]$CategoryName,

    [Parameter(Mandatory)]
    [object[]]$Applications
  )

  $Card = New-Object System.Windows.Controls.Border
  $Card.Background = "#1C1F26"
  $Card.BorderBrush = "#2C2F38"
  $Card.BorderThickness = "1"
  $Card.CornerRadius = "10"
  $Card.Padding = "14"
  $Card.Width = 340
  $Card.Margin = "0,0,10,10"

  $Stack = New-Object System.Windows.Controls.StackPanel
  $Card.Child = $Stack

  $HeaderPanel = New-Object System.Windows.Controls.StackPanel
  $HeaderPanel.Orientation = "Horizontal"
  $HeaderPanel.Margin = "0,0,0,8"

  $HeaderIcon = New-GuiCategoryIcon -CategoryName $CategoryName -Color "#9A9EA8"
  $HeaderIcon.Margin = "0,0,8,0"
  $HeaderPanel.Children.Add($HeaderIcon) | Out-Null

  $Header = New-Object System.Windows.Controls.TextBlock
  $Header.Text = $CategoryName.ToUpper()
  $Header.FontSize = 11
  $Header.FontWeight = "Bold"
  $Header.Foreground = "#9A9EA8"
  $Header.VerticalAlignment = "Center"
  $HeaderPanel.Children.Add($Header) | Out-Null

  $Stack.Children.Add($HeaderPanel) | Out-Null

  foreach ($Application in $Applications) {
    $Row = New-GuiApplicationRow -Application $Application
    $Stack.Children.Add($Row) | Out-Null
  }

  return $Card
}

function Update-GuiApplicationGrid {
  param(
    [Parameter(Mandatory)]
    [System.Windows.Controls.ItemsControl]$GridPanel
  )

  $GridPanel.Items.Clear()

  $Grouped = $script:Applications | Group-Object Category

  foreach ($Group in $Grouped) {
    $SortedApplications = $Group.Group | Sort-Object Name
    $Card = New-GuiCategoryCard -CategoryName $Group.Name -Applications $SortedApplications
    $GridPanel.Items.Add($Card) | Out-Null
  }
}

function Update-GuiSelectedCount {
  param(
    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$CountText
  )

  $SelectedCount = @($script:Applications | Where-Object { $_.Selected -eq $true }).Count
  $CountText.Text = "$SelectedCount selected"
}

function Start-GuiApplicationQueue {
  param(
    [Parameter(Mandatory)]
    [ValidateSet("Install", "Uninstall")]
    [string]$Mode,

    [Parameter(Mandatory)]
    [AllowEmptyCollection()]
    [PSCustomObject[]]$Applications,

    [int]$PreSkippedCount = 0,

    [string[]]$PreFailureMessages = @(),

    [Parameter(Mandatory)]
    [System.Windows.Controls.ItemsControl]$GridPanel,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$CountText,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Button[]]$ButtonsToDisable,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Button]$CancelButton,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Panel]$QueueProgressPanel,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$QueueProgressText,

    [Parameter(Mandatory)]
    [System.Windows.Controls.ProgressBar]$QueueProgressBar,

    [Parameter(Mandatory)]
    [hashtable]$ModalControls
  )

  if ($Applications.Count -eq 0) {
    if ($PreFailureMessages.Count -eq 0) {
      # Nothing real happened and nothing failed (every selected application was declined or already not installed) -- no progress UI and no completion popup either, since there's nothing worth reporting for an action the user themselves cancelled out of.
      return
    }

    # A real failure still happened even though no application was actually queued (e.g. a pre-check failure before confirmation), so this case alone is still worth surfacing.
    $Counts = if ($Mode -eq "Install") {
      [ordered]@{ Installed = 0; Skipped = $PreSkippedCount; Blocked = 0; Failed = $PreFailureMessages.Count; "Not Found" = 0 }
    }
    else {
      [ordered]@{ Uninstalled = 0; Skipped = $PreSkippedCount; Failed = $PreFailureMessages.Count }
    }

    $ModalTitle = if ($Mode -eq "Install") { "Installation Complete" } else { "Uninstallation Complete" }

    Show-GuiCompletionModal -Overlay $ModalControls.Overlay -IconSuccess $ModalControls.IconSuccess -IconWarning $ModalControls.IconWarning `
      -TitleText $ModalControls.TitleText -CountsPanel $ModalControls.CountsPanel -DetailsCard $ModalControls.DetailsCard `
      -DetailsPanel $ModalControls.DetailsPanel -Title $ModalTitle -Counts $Counts -FailureMessages $PreFailureMessages

    return
  }

  foreach ($Button in $ButtonsToDisable) {
    $Button.IsEnabled = $false
    $Button.Visibility = "Collapsed"
  }

  $script:GuiQueueRunning = $true
  $CountText.Visibility = "Collapsed"
  $CancelButton.Visibility = "Visible"
  $CancelButton.IsEnabled = $true
  $CancelButton.Content = "Cancel"
  $QueueProgressPanel.Visibility = "Visible"
  $QueueProgressText.Text = if ($Mode -eq "Install") { "Installing..." } else { "Uninstalling..." }
  $QueueProgressBar.Value = 0

  $RootPath = $script:ITDeploymentToolRoot
  $LogPath = $script:LogFilePath
  $ProgressQueue = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
  $CancelQueue = [System.Collections.Concurrent.ConcurrentQueue[bool]]::new()

  # Deliberately duplicated from Start.ps1's $ModulePaths rather than reused -- this is the minimal subset the install/uninstall call graph actually touches, re-loaded fresh inside a background runspace that starts with no session state of its own. Keep in sync if a new install type module is ever added to the router.
  $BackgroundScript = {
    param(
      [string]$RootPath,
      [string]$LogPath,
      [string]$Mode,
      [object[]]$Applications,
      [System.Collections.Concurrent.ConcurrentQueue[object]]$ProgressQueue,
      [System.Collections.Concurrent.ConcurrentQueue[bool]]$CancelQueue
    )

    $ModulePaths = @(
      "Core\Logging.ps1"
      "Applications\InstalledApplications.ps1"
      "Applications\ApplicationProcessCheck.ps1"
      "Applications\MicrosoftTeams.ps1"
      "Installation\InstallationResult.ps1"
      "Installation\UninstallationResult.ps1"
      "Installation\WingetInstaller.ps1"
      "Installation\OfflineInstaller.ps1"
      "Installation\MsiInstaller.ps1"
      "Installation\AppxInstaller.ps1"
      "Installation\ScriptInstaller.ps1"
      "Installation\ZipInstaller.ps1"
      "Installation\CrowdStrikeInstaller.ps1"
      "Installation\OfficeIsoInstaller.ps1"
      "Installation\Office2021ImgInstaller.ps1"
      "Installation\CloudInstallerFetch.ps1"
      "Installation\InstallationRouter.ps1"
      "Installation\UninstallationRouter.ps1"
    )

    foreach ($ModulePath in $ModulePaths) {
      . (Join-Path $RootPath "Modules\$ModulePath")
    }

    # Must happen AFTER dot-sourcing: Core\Logging.ps1's own top-level code resets $script:LogFilePath to $null when it loads, which would silently undo this assignment if it ran first.
    $script:ITDeploymentToolRoot = $RootPath
    $script:LogFilePath = $LogPath
    $ConfirmPreference = "None"

    $Results = New-Object System.Collections.ArrayList

    $TotalCount = $Applications.Count
    $Index = 0
    $CancelRequested = $false

    if ($Mode -eq "Install") {
      Update-InstalledApplicationRegistryCache

      foreach ($Application in $Applications) {
        $Index++

        if ((-not $CancelRequested) -and ($CancelQueue.Count -gt 0)) {
          $CancelRequested = $true
        }

        if ($CancelRequested) {
          [void]$Results.Add([PSCustomObject]@{ ApplicationName = $Application.Name; Status = "Cancelled"; Message = "$($Application.Name) was cancelled before starting." })
          continue
        }

        $ProgressQueue.Enqueue([PSCustomObject]@{ Index = $Index; Total = $TotalCount; Message = ("Installing {0} of {1}: {2}..." -f $Index, $TotalCount, $Application.Name) })

        $AlreadyInstalled = Test-ApplicationInstalled -Application $Application

        if ($AlreadyInstalled) {
          Write-DeploymentLog -Message ("{0} is already installed. Skipped." -f $Application.Name) -Level "INFO"
          [void]$Results.Add([PSCustomObject]@{ ApplicationName = $Application.Name; Status = "Skipped"; Message = "$($Application.Name) is already installed. Skipped." })
          continue
        }

        $BlockingProcesses = @(Get-BlockingApplicationProcesses -Application $Application)

        if ($BlockingProcesses.Count -gt 0) {
          $ProcessNames = ($BlockingProcesses | Select-Object -ExpandProperty ProcessName -Unique | Sort-Object) -join ", "
          Write-DeploymentLog -Message ("{0} was skipped because these processes are running: {1}" -f $Application.Name, $ProcessNames) -Level "WARNING"
          [void]$Results.Add([PSCustomObject]@{ ApplicationName = $Application.Name; Status = "Blocked"; Message = "$($Application.Name) was skipped because these processes are running: $ProcessNames" })
          continue
        }

        # A cloud-sourced application (CrowdStrike, Office LTSC 2024, Office 2021 LOP, SAP GUI) correctly reports unavailable here on a fresh device that has not fetched its package yet -- that is not the same as genuinely unavailable, since Install-ApplicationByType fetches it automatically before installing. Only short-circuits to Not Found when there is neither a local package nor a configured cloud source to fetch one from.
        $InstallerAvailable = Test-ApplicationInstallerAvailable -Application $Application
        $CloudSourceConfigured = Test-CloudInstallerConfigured -Application $Application

        if ((-not $InstallerAvailable) -and (-not $CloudSourceConfigured)) {
          Write-DeploymentLog -Message ("Installer was not found or is unavailable for {0}." -f $Application.Name) -Level "ERROR"
          [void]$Results.Add([PSCustomObject]@{ ApplicationName = $Application.Name; Status = "NotFound"; Message = "Installer was not found or is unavailable for $($Application.Name)." })
          continue
        }

        $InstallationResult = Install-ApplicationByType -Application $Application

        [void]$Results.Add([PSCustomObject]@{ ApplicationName = $Application.Name; Status = $InstallationResult.Status; Message = $InstallationResult.Message })
      }
    }
    else {
      foreach ($Application in $Applications) {
        $Index++

        if ((-not $CancelRequested) -and ($CancelQueue.Count -gt 0)) {
          $CancelRequested = $true
        }

        if ($CancelRequested) {
          [void]$Results.Add([PSCustomObject]@{ ApplicationName = $Application.Name; Status = "Cancelled"; Message = "$($Application.Name) was cancelled before starting." })
          continue
        }

        $ProgressQueue.Enqueue([PSCustomObject]@{ Index = $Index; Total = $TotalCount; Message = ("Uninstalling {0} of {1}: {2}..." -f $Index, $TotalCount, $Application.Name) })

        $BlockingProcesses = @(Get-BlockingApplicationProcesses -Application $Application)

        if ($BlockingProcesses.Count -gt 0) {
          $ProcessNames = ($BlockingProcesses | Select-Object -ExpandProperty ProcessName -Unique | Sort-Object) -join ", "
          Write-DeploymentLog -Message ("{0} was skipped because these processes are running: {1}" -f $Application.Name, $ProcessNames) -Level "WARNING"
          [void]$Results.Add([PSCustomObject]@{ ApplicationName = $Application.Name; Status = "Skipped"; Message = "$($Application.Name) was skipped because these processes are running: $ProcessNames" })
          continue
        }

        $UninstallationResult = Uninstall-ApplicationByType -Application $Application

        [void]$Results.Add([PSCustomObject]@{ ApplicationName = $Application.Name; Status = $UninstallationResult.Status; Message = $UninstallationResult.Message })
      }
    }

    return @($Results)
  }

  $Runspace = [runspacefactory]::CreateRunspace()
  $Runspace.Open()

  $PowerShellInstance = [powershell]::Create()
  $PowerShellInstance.Runspace = $Runspace

  [void]$PowerShellInstance.AddScript($BackgroundScript)
  [void]$PowerShellInstance.AddArgument($RootPath)
  [void]$PowerShellInstance.AddArgument($LogPath)
  [void]$PowerShellInstance.AddArgument($Mode)
  [void]$PowerShellInstance.AddArgument($Applications)
  [void]$PowerShellInstance.AddArgument($ProgressQueue)
  [void]$PowerShellInstance.AddArgument($CancelQueue)

  $AsyncResult = $PowerShellInstance.BeginInvoke()

  $script:GuiQueueAsyncResult = $AsyncResult
  $script:GuiQueuePowerShell = $PowerShellInstance
  $script:GuiQueueRunspace = $Runspace
  $script:GuiQueueMode = $Mode
  $script:GuiQueueGridPanel = $GridPanel
  $script:GuiQueueCountText = $CountText
  $script:GuiQueueButtonsToDisable = $ButtonsToDisable
  $script:GuiQueueCancelButton = $CancelButton
  $script:GuiQueueProgressPanel = $QueueProgressPanel
  $script:GuiQueueProgressText = $QueueProgressText
  $script:GuiQueueProgressBar = $QueueProgressBar
  $script:GuiQueueModalControls = $ModalControls
  $script:GuiQueuePreSkippedCount = $PreSkippedCount
  $script:GuiQueuePreFailureMessages = $PreFailureMessages
  $script:GuiQueueProgressQueue = $ProgressQueue
  $script:GuiQueueCancelQueue = $CancelQueue

  $Timer = New-Object System.Windows.Threading.DispatcherTimer
  $Timer.Interval = [TimeSpan]::FromMilliseconds(300)
  $script:GuiQueueTimer = $Timer

  # Plain scriptblock -- deliberately NOT .GetNewClosure()'d. This function returns before the timer ever ticks, so a closure would need to capture every variable below by value; GetNewClosure() was already found earlier in this file to break dot-sourced function resolution inside WPF event handlers (that's why the toolbar buttons broke and had to be fixed by removing it). Reading everything back from $script:GuiQueue* instead mirrors the same proven-safe pattern New-GuiLogListRow's per-row click handler already uses.
  $Timer.Add_Tick({
    $LatestProgress = $null
    $DequeuedProgress = $null

    while ($script:GuiQueueProgressQueue.TryDequeue([ref]$DequeuedProgress)) {
      $LatestProgress = $DequeuedProgress
    }

    if ($null -ne $LatestProgress) {
      $script:GuiQueueProgressText.Text = $LatestProgress.Message
      $script:GuiQueueProgressBar.Value = if ($LatestProgress.Total -gt 0) { ($LatestProgress.Index / $LatestProgress.Total) * 100 } else { 0 }
    }

    if (-not $script:GuiQueueAsyncResult.IsCompleted) {
      return
    }

    $script:GuiQueueTimer.Stop()

    try {
      $QueueResults = @($script:GuiQueuePowerShell.EndInvoke($script:GuiQueueAsyncResult))

      if ($script:GuiQueuePowerShell.HadErrors) {
        foreach ($QueueError in $script:GuiQueuePowerShell.Streams.Error) {
          Write-DeploymentLog -Message ([string]$QueueError) -Level "ERROR"
        }
      }

      $CancelledCount = @($QueueResults | Where-Object { $_.Status -eq "Cancelled" }).Count

      if ($script:GuiQueueMode -eq "Install") {
        $InstalledCount = @($QueueResults | Where-Object { $_.Status -eq "Installed" }).Count
        $SkippedCount = @($QueueResults | Where-Object { $_.Status -eq "Skipped" }).Count
        $BlockedCount = @($QueueResults | Where-Object { $_.Status -eq "Blocked" }).Count
        $NotFoundCount = @($QueueResults | Where-Object { $_.Status -eq "NotFound" }).Count
        $FailedResults = @($QueueResults | Where-Object { $_.Status -notin @("Installed", "Skipped", "Blocked", "NotFound", "Cancelled") })
        $FailedCount = $FailedResults.Count

        $Counts = [ordered]@{
          Installed = $InstalledCount
          Skipped   = $SkippedCount
          Blocked   = $BlockedCount
          Failed    = $FailedCount
          "Not Found" = $NotFoundCount
        }

        $FailureMessages = @($FailedResults | ForEach-Object { $_.Message })
      }
      else {
        $UninstalledCount = @($QueueResults | Where-Object { $_.Status -eq "Uninstalled" }).Count
        $SkippedCount = @($QueueResults | Where-Object { $_.Status -eq "Skipped" }).Count + $script:GuiQueuePreSkippedCount
        $FailedResults = @($QueueResults | Where-Object { $_.Status -notin @("Uninstalled", "Skipped", "Cancelled") })
        $FailedCount = $FailedResults.Count

        $Counts = [ordered]@{
          Uninstalled = $UninstalledCount
          Skipped     = $SkippedCount
          Failed      = $FailedCount
        }

        $FailureMessages = @($script:GuiQueuePreFailureMessages) + @($FailedResults | ForEach-Object { $_.Message })
      }

      if ($CancelledCount -gt 0) {
        $Counts["Cancelled"] = $CancelledCount
      }

      $ModalTitle = if ($script:GuiQueueMode -eq "Install") { "Installation Complete" } else { "Uninstallation Complete" }

      if ($CancelledCount -gt 0) {
        $ModalTitle += " (Cancelled)"
      }

      Update-ApplicationInstallationStatus
      Update-GuiApplicationGrid -GridPanel $script:GuiQueueGridPanel
      Update-GuiSelectedCount -CountText $script:GuiQueueCountText

      Show-GuiCompletionModal -Overlay $script:GuiQueueModalControls.Overlay -IconSuccess $script:GuiQueueModalControls.IconSuccess `
        -IconWarning $script:GuiQueueModalControls.IconWarning -TitleText $script:GuiQueueModalControls.TitleText `
        -CountsPanel $script:GuiQueueModalControls.CountsPanel -DetailsCard $script:GuiQueueModalControls.DetailsCard `
        -DetailsPanel $script:GuiQueueModalControls.DetailsPanel -Title $ModalTitle -Counts $Counts -FailureMessages $FailureMessages
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Queue error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
    finally {
      $script:GuiQueuePowerShell.Dispose()
      $script:GuiQueueRunspace.Close()
      $script:GuiQueueRunspace.Dispose()

      foreach ($Button in $script:GuiQueueButtonsToDisable) {
        $Button.IsEnabled = $true
        $Button.Visibility = "Visible"
      }

      $script:GuiQueueCancelButton.Visibility = "Collapsed"
      $script:GuiQueueProgressPanel.Visibility = "Collapsed"
      $script:GuiQueueCountText.Visibility = "Visible"

      $script:GuiQueueRunning = $false
    }
  })

  $Timer.Start()
}

function Invoke-GuiInstallQueue {
  param(
    [Parameter(Mandatory)]
    [System.Windows.Controls.ItemsControl]$GridPanel,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$CountText,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Button]$InstallButton,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Button]$UninstallButton,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Button]$CancelButton,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Panel]$QueueProgressPanel,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$QueueProgressText,

    [Parameter(Mandatory)]
    [System.Windows.Controls.ProgressBar]$QueueProgressBar,

    [Parameter(Mandatory)]
    [hashtable]$ModalControls
  )

  $SelectedApplications = @(Get-SelectedApplications)

  if ($SelectedApplications.Count -eq 0) {
    Show-GuiDialog -Title "Nothing Selected" -Icon Info -Message "No applications selected."
    return
  }

  $ClonedApplications = @($SelectedApplications | ForEach-Object { $_.PSObject.Copy() })

  Start-GuiApplicationQueue -Mode "Install" -Applications $ClonedApplications -GridPanel $GridPanel -CountText $CountText `
    -ButtonsToDisable @($InstallButton, $UninstallButton) -CancelButton $CancelButton -QueueProgressPanel $QueueProgressPanel `
    -QueueProgressText $QueueProgressText -QueueProgressBar $QueueProgressBar -ModalControls $ModalControls
}

function Invoke-GuiUninstallQueue {
  param(
    [Parameter(Mandatory)]
    [System.Windows.Controls.ItemsControl]$GridPanel,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$CountText,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Button]$InstallButton,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Button]$UninstallButton,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Button]$CancelButton,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Panel]$QueueProgressPanel,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$QueueProgressText,

    [Parameter(Mandatory)]
    [System.Windows.Controls.ProgressBar]$QueueProgressBar,

    [Parameter(Mandatory)]
    [hashtable]$ModalControls
  )

  $SelectedApplications = @(Get-SelectedApplications)

  if ($SelectedApplications.Count -eq 0) {
    Show-GuiDialog -Title "Nothing Selected" -Icon Info -Message "No applications selected."
    return
  }

  $ApplicationsToUninstall = @()
  $PreSkippedCount = 0

  foreach ($Application in $SelectedApplications) {
    $IsInstalled = Test-ApplicationInstalled -Application $Application

    if (-not $IsInstalled) {
      $PreSkippedCount++
      Write-DeploymentLog -Message ("{0} is not installed. Skipped." -f $Application.Name) -Level "INFO"
      continue
    }

    $Confirmation = Show-GuiDialog -Title "Confirm Uninstall" -Icon Warning -Buttons YesNo -Message "Uninstall $($Application.Name)?"

    if ($Confirmation -ne "Yes") {
      $PreSkippedCount++
      Write-DeploymentLog -Message ("{0} uninstallation was declined." -f $Application.Name) -Level "INFO"
      continue
    }

    $ApplicationsToUninstall += $Application.PSObject.Copy()
  }

  Start-GuiApplicationQueue -Mode "Uninstall" -Applications $ApplicationsToUninstall -PreSkippedCount $PreSkippedCount -GridPanel $GridPanel -CountText $CountText `
    -ButtonsToDisable @($InstallButton, $UninstallButton) -CancelButton $CancelButton -QueueProgressPanel $QueueProgressPanel `
    -QueueProgressText $QueueProgressText -QueueProgressBar $QueueProgressBar -ModalControls $ModalControls
}

function Initialize-GuiApplicationsScreen {
  # FindName + click-handler wiring for this screen, called once from Show-MainWindow (GuiWindow.ps1). Returns the Nav Border/Text/Icon triple so the orchestrator can add this screen to the shared nav arrays.
  param(
    [Parameter(Mandatory)]
    [System.Windows.Window]$Window,

    [Parameter(Mandatory)]
    [hashtable]$CompletionModalControls
  )

  $AppGridPanel = $Window.FindName("AppGridPanel")
  $SelectedCountText = $Window.FindName("SelectedCountText")
  $SelectAllButton = $Window.FindName("SelectAllButton")
  $SelectRecommendedButton = $Window.FindName("SelectRecommendedButton")
  $ClearAllButton = $Window.FindName("ClearAllButton")
  $InstallSelectedButton = $Window.FindName("InstallSelectedButton")
  $UninstallSelectedButton = $Window.FindName("UninstallSelectedButton")
  $CancelQueueButton = $Window.FindName("CancelQueueButton")
  $QueueProgressPanel = $Window.FindName("QueueProgressPanel")
  $QueueProgressText = $Window.FindName("QueueProgressText")
  $QueueProgressBar = $Window.FindName("QueueProgressBar")
  $NavApplications = $Window.FindName("NavApplications")
  $NavApplicationsText = $Window.FindName("NavApplicationsText")
  $NavApplicationsIcon = $Window.FindName("NavApplicationsIcon")

  $script:GuiQueueRunning = $false
  $script:GuiSelectedCountText = $SelectedCountText
  $script:GuiApplicationsToolbar = $Window.FindName("ApplicationsToolbar")
  $script:GuiApplicationsScrollViewer = $Window.FindName("ApplicationsScrollViewer")

  Update-GuiApplicationGrid -GridPanel $AppGridPanel
  Update-GuiSelectedCount -CountText $SelectedCountText

  $SelectAllButton.Add_Click({
    try {
      Select-AllApplications
      Update-GuiApplicationGrid -GridPanel $AppGridPanel
      Update-GuiSelectedCount -CountText $SelectedCountText
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Select All error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $SelectRecommendedButton.Add_Click({
    try {
      Select-RecommendedApplications | Out-Null
      Update-GuiApplicationGrid -GridPanel $AppGridPanel
      Update-GuiSelectedCount -CountText $SelectedCountText
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Select Recommended error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $ClearAllButton.Add_Click({
    try {
      Clear-AllApplications
      Update-GuiApplicationGrid -GridPanel $AppGridPanel
      Update-GuiSelectedCount -CountText $SelectedCountText
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Clear All error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $InstallSelectedButton.Add_Click({
    try {
      Invoke-GuiInstallQueue -GridPanel $AppGridPanel -CountText $SelectedCountText -InstallButton $InstallSelectedButton -UninstallButton $UninstallSelectedButton `
        -CancelButton $CancelQueueButton -QueueProgressPanel $QueueProgressPanel -QueueProgressText $QueueProgressText -QueueProgressBar $QueueProgressBar `
        -ModalControls $CompletionModalControls
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Install error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $UninstallSelectedButton.Add_Click({
    try {
      Invoke-GuiUninstallQueue -GridPanel $AppGridPanel -CountText $SelectedCountText -InstallButton $InstallSelectedButton -UninstallButton $UninstallSelectedButton `
        -CancelButton $CancelQueueButton -QueueProgressPanel $QueueProgressPanel -QueueProgressText $QueueProgressText -QueueProgressBar $QueueProgressBar `
        -ModalControls $CompletionModalControls
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Uninstall error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $CancelQueueButton.Add_Click({
    try {
      $CancelQueueButton.IsEnabled = $false
      $CancelQueueButton.Content = "Cancelling..."
      $script:GuiQueueCancelQueue.Enqueue($true)
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Cancel error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $NavApplications.Add_MouseLeftButtonUp({
    try {
      Switch-GuiScreen -ScreenName "Applications" -ActiveBorder $NavApplications -ActiveText $NavApplicationsText -ActiveIcon $NavApplicationsIcon
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Navigation error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  return @{
    NavBorder = $NavApplications
    NavText   = $NavApplicationsText
    NavIcon   = $NavApplicationsIcon
  }
}
