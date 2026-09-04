# ============================================================
# GUI WINDOW (main window shell: navigation, system info bar, entry point)
# ============================================================
# Per-screen logic lives in each screen's own Gui*Screen.ps1 file (GuiApplicationsScreen.ps1, GuiWindowsSetupScreen.ps1, GuiDeviceDetailsScreen.ps1, GuiAssetIdScreen.ps1, GuiDeploymentValidationScreen.ps1, GuiDeploymentLogsScreen.ps1, GuiTempCleanupScreen.ps1 -- all loaded before this file), each exposing an Initialize-GuiXScreen function that does that screen's own FindName + click-handler wiring and returns its Nav Border/Text/Icon triple (plus, for Windows Setup/Device Details/Asset ID, the pieces their one shared Refresh mechanism needs). This file ties them together: cross-screen navigation, the system info bar, the completion modal's own Ok/Copy buttons, and the Show-MainWindow entry point that calls each screen's Initialize function once.

function Start-GuiFadeIn {
  param(
    [Parameter(Mandatory)]
    [System.Windows.UIElement]$Element
  )

  $Element.Opacity = 0
  $Animation = New-Object System.Windows.Media.Animation.DoubleAnimation(0, 1, (New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds(160))))
  $Element.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $Animation)
}

function Show-GuiScreenLoadingState {
  param(
    [Parameter(Mandatory)]
    [System.Windows.Controls.Panel]$Panel,

    [Parameter(Mandatory)]
    [string]$Message
  )

  $Panel.Children.Clear()

  $LoadingText = New-Object System.Windows.Controls.TextBlock
  $LoadingText.Text = $Message
  $LoadingText.Foreground = "#9A9EA8"
  $LoadingText.FontSize = 13
  $LoadingText.Margin = "0,20,0,0"
  $Panel.Children.Add($LoadingText) | Out-Null

  # The checks that follow this call run synchronously on the UI thread and can take the better part of a second (CIM/BIOS queries, powercfg.exe). Forcing a Render-priority dispatch here flushes the "Loading..." text to screen first, so the tab switch itself feels instant instead of frozen.
  $Panel.Dispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Render)
}

function Switch-GuiScreen {
  param(
    [Parameter(Mandatory)]
    [string]$ScreenName,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Border]$ActiveBorder,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$ActiveText,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Canvas]$ActiveIcon
  )

  foreach ($NavBorder in $script:GuiNavBorders) {
    $NavBorder.Background = "Transparent"
  }

  foreach ($NavText in $script:GuiNavTexts) {
    $NavText.Foreground = "#9A9EA8"
    $NavText.FontWeight = "Normal"
  }

  foreach ($NavIcon in $script:GuiNavIcons) {
    Set-GuiIconColor -IconCanvas $NavIcon -Color "#9A9EA8"
  }

  $ActiveBorder.Background = "#2438BDF8"
  $ActiveText.Foreground = "#38BDF8"
  $ActiveText.FontWeight = "SemiBold"
  Set-GuiIconColor -IconCanvas $ActiveIcon -Color "#38BDF8"

  # Every screen is hidden first, then only the requested one is shown. Doing it this way keeps each branch to the two lines that actually differ, instead of repeating the full visibility list once per screen.
  $script:GuiApplicationsToolbar.Visibility = "Collapsed"
  $script:GuiApplicationsScrollViewer.Visibility = "Collapsed"
  $script:GuiPlaceholderText.Visibility = "Collapsed"

  # Employee mode never initializes any of these six screens (Show-MainWindow), so their $script:Gui* toolbar/scrollviewer variables are $null -- setting a property on $null throws "The property '...' cannot be found on this object", not silently a no-op, so this whole block is skipped rather than guarded line by line.
  if ($script:DeploymentMode -ne "Employee") {
    $script:GuiDeploymentValidationToolbar.Visibility = "Collapsed"
    $script:GuiDeploymentValidationScrollViewer.Visibility = "Collapsed"
    $script:GuiDeploymentLogsToolbar.Visibility = "Collapsed"
    $script:GuiDeploymentLogsContent.Visibility = "Collapsed"
    $script:GuiWindowsSetupToolbar.Visibility = "Collapsed"
    $script:GuiWindowsSetupScrollViewer.Visibility = "Collapsed"
    $script:GuiDeviceDetailsToolbar.Visibility = "Collapsed"
    $script:GuiDeviceDetailsScrollViewer.Visibility = "Collapsed"
    $script:GuiAssetIdToolbar.Visibility = "Collapsed"
    $script:GuiAssetIdScrollViewer.Visibility = "Collapsed"
    $script:GuiTempCleanupToolbar.Visibility = "Collapsed"
    $script:GuiTempCleanupScrollViewer.Visibility = "Collapsed"
  }

  if ($ScreenName -eq "Applications") {
    $script:GuiApplicationsToolbar.Visibility = "Visible"
    $script:GuiApplicationsScrollViewer.Visibility = "Visible"

    Start-GuiFadeIn -Element $script:GuiApplicationsScrollViewer
  }
  elseif ($ScreenName -eq "Deployment Validation") {
    $script:GuiDeploymentValidationToolbar.Visibility = "Visible"
    $script:GuiDeploymentValidationScrollViewer.Visibility = "Visible"

    if (-not $script:GuiDeploymentValidationLoaded) {
      $script:GuiDeploymentValidationLoaded = $true
      Start-GuiDeploymentValidationLoad -ValidationPanel $script:GuiDeploymentValidationPanel -SummaryText $script:GuiValidationSummaryText -RerunButton $script:GuiRerunValidationButton
    }

    Start-GuiFadeIn -Element $script:GuiDeploymentValidationScrollViewer
  }
  elseif ($ScreenName -eq "Deployment Logs") {
    $script:GuiDeploymentLogsToolbar.Visibility = "Visible"
    $script:GuiDeploymentLogsContent.Visibility = "Visible"

    if (-not $script:GuiDeploymentLogsLoaded) {
      $script:GuiDeploymentLogsLoaded = $true
      Update-GuiLogsList -ListPanel $script:GuiDeploymentLogsPanel -ContentTextBox $script:GuiLogContentTextBox -NameText $script:GuiSelectedLogNameText
    }

    Start-GuiFadeIn -Element $script:GuiDeploymentLogsContent
  }
  elseif ($ScreenName -eq "Windows Setup" -or $ScreenName -eq "Device Details" -or $ScreenName -eq "Asset ID") {
    # All three screens are fed by one shared device report, so whichever is opened first performs the load and the others reuse it. Asset ID can only ever be opened via NavAssetId, which stays Collapsed until that shared load confirms this device is a ThinkPad, so there is no path here where this screen shows without real data behind it.
    if ($ScreenName -eq "Windows Setup") {
      $script:GuiWindowsSetupToolbar.Visibility = "Visible"
      $script:GuiWindowsSetupScrollViewer.Visibility = "Visible"
      $ActiveScrollViewer = $script:GuiWindowsSetupScrollViewer
    }
    elseif ($ScreenName -eq "Device Details") {
      $script:GuiDeviceDetailsToolbar.Visibility = "Visible"
      $script:GuiDeviceDetailsScrollViewer.Visibility = "Visible"
      $ActiveScrollViewer = $script:GuiDeviceDetailsScrollViewer
    }
    else {
      $script:GuiAssetIdToolbar.Visibility = "Visible"
      $script:GuiAssetIdScrollViewer.Visibility = "Visible"
      $ActiveScrollViewer = $script:GuiAssetIdScrollViewer
    }

    if (-not $script:GuiWindowsConfigLoaded) {
      $script:GuiWindowsConfigLoaded = $true

      # Runs the CIM/BIOS/powercfg queries on a background runspace (the same pattern used for install/uninstall queues) so this first load never blocks the UI thread. Start-GuiFadeIn runs once the data actually arrives, inside Start-GuiWindowsConfigLoad's own completion handler, rather than immediately below like the other screens.
      Start-GuiWindowsConfigLoad -DeviceFields $script:GuiWindowsConfigDeviceFields -CurrentNameText $script:GuiCurrentComputerNameText -LocalUsersListPanel $script:GuiLocalUsersListPanel -CurrentPluggedInText $script:GuiCurrentPluggedInText -CurrentBatteryText $script:GuiCurrentBatteryText -RefreshButtons $script:GuiRefreshWindowsConfigButtons -ScrollViewer $ActiveScrollViewer -NavAssetId $script:GuiNavAssetId -AssetIdFieldTextBoxes $script:GuiAssetIdFieldTextBoxes
    }
    else {
      Start-GuiFadeIn -Element $ActiveScrollViewer
    }
  }
  elseif ($ScreenName -eq "Temp Cleanup") {
    $script:GuiTempCleanupToolbar.Visibility = "Visible"
    $script:GuiTempCleanupScrollViewer.Visibility = "Visible"

    if (-not $script:GuiTempCleanupLoaded) {
      $script:GuiTempCleanupLoaded = $true
      Start-GuiTempCleanupScan -CardControls $script:GuiTempCleanupCardControls -RefreshButton $script:GuiRefreshTempCleanupButton -CleanButton $script:GuiCleanSelectedTempButton
    }

    Start-GuiFadeIn -Element $script:GuiTempCleanupScrollViewer
  }
  else {
    $script:GuiPlaceholderText.Text = "$ScreenName screen - not built yet"
    $script:GuiPlaceholderText.Visibility = "Visible"
  }
}

function Update-GuiSystemInfoBar {
  param(
    [Parameter(Mandatory)]
    [System.Windows.Window]$Window
  )

  Get-SystemInformation
  Test-Administrator -PassThru | Out-Null
  Test-Internet -PassThru | Out-Null
  Test-Winget -PassThru | Out-Null

  $Window.FindName("ComputerNameText").Text = $SystemInfo.ComputerName
  $Window.FindName("UserNameText").Text = $SystemInfo.LoggedUser
  $Window.FindName("ModelText").Text = $SystemInfo.Model
  $Window.FindName("EditionText").Text = $SystemInfo.WindowsEdition

  $AdminStatusColor = if ($SystemInfo.IsAdministrator) { "#34D399" } else { "#F2555A" }
  $Window.FindName("AdminStatusText").Foreground = $AdminStatusColor
  $Window.FindName("AdminStatusDot").Fill = $AdminStatusColor

  $InternetStatusColor = if ($SystemInfo.InternetStatus) { "#34D399" } else { "#F2555A" }
  $Window.FindName("InternetStatusText").Foreground = $InternetStatusColor
  $Window.FindName("InternetStatusDot").Fill = $InternetStatusColor

  $WingetStatusColor = if ($SystemInfo.WingetAvailable) { "#34D399" } else { "#F2555A" }
  $Window.FindName("WingetStatusText").Foreground = $WingetStatusColor
  $Window.FindName("WingetStatusDot").Fill = $WingetStatusColor

  $ElevationLabel = if ($SystemInfo.IsAdministrator) { "Elevated (Administrator)" } else { "Not Elevated" }
  $Window.FindName("SidebarFooterText").Text = "Session started $($script:GuiSessionStartTime.ToString('hh:mm tt'))`n$ElevationLabel"
}

function Start-GuiSelfDeleteOnExit {
  # Writes the deleter to TEMP rather than inside the tool's own folder, since a script can't reliably delete the file it's currently running from; Wait-Process blocks it until this process has actually exited, so it never races a file this process still has open.
  $ToolRoot = $script:ITDeploymentToolRoot
  $CurrentProcessId = $PID
  $DeleterScriptPath = Join-Path $env:TEMP "it-deployment-tool-self-delete-$CurrentProcessId.ps1"

  $DeleterScript = @"
Wait-Process -Id $CurrentProcessId -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Remove-Item -LiteralPath '$ToolRoot' -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath '$DeleterScriptPath' -Force -ErrorAction SilentlyContinue
"@

  Set-Content -LiteralPath $DeleterScriptPath -Value $DeleterScript -Encoding UTF8

  Start-Process -FilePath "powershell.exe" `
    -ArgumentList @("-NoProfile", "-WindowStyle", "Hidden", "-ExecutionPolicy", "Bypass", "-File", $DeleterScriptPath) `
    -WindowStyle Hidden
}

function Show-MainWindow {
  param(
    [switch]$DeleteOnClose
  )

  Add-Type -AssemblyName PresentationFramework

  # Only ever set by Deploy.ps1's own bootstrap launch, never by a manually run .\Start.ps1 -Gui -- read by the Closing handler below to confirm and permanently delete this tool's own folder from a device it was deployed to.
  $script:GuiDeleteOnClose = [bool]$DeleteOnClose

  $script:GuiSessionStartTime = Get-Date

  Initialize-DeploymentLog -Version $AppVersion

  Initialize-Applications | Out-Null
  Update-ApplicationInstallationStatus

  $XamlPath = Join-Path $script:ITDeploymentToolRoot "Modules\Gui\MainWindow.xaml"

  [xml]$WindowXaml = Get-Content -LiteralPath $XamlPath -Raw

  $Reader = New-Object System.Xml.XmlNodeReader $WindowXaml
  $Window = [Windows.Markup.XamlReader]::Load($Reader)

  # Show-GuiDialog (GuiDialog.ps1) needs a reference to this window to size and center itself as an owned dialog, without threading an -Owner parameter through every one of its call sites across the Gui modules.
  $script:GuiMainWindow = $Window

  # Nunito is bundled as a variable font rather than installed system-wide, since this tool is copied directly to technician machines rather than installed. Loaded via an absolute folder URI (not a relative XAML path) because XamlReader.Load has no base URI to resolve a relative FontFamily reference against here -- every other path in this app already uses $script:ITDeploymentToolRoot for the same reason. Falls back to the XAML's own Segoe UI default if the font file is ever missing (e.g. not yet copied to this machine), rather than failing to start.
  try {
    $FontsDirectory = Join-Path $script:ITDeploymentToolRoot "Modules\Gui\Fonts"
    $FontsUri = New-Object System.Uri(($FontsDirectory.TrimEnd('\') + '\'), [System.UriKind]::Absolute)
    $Window.FontFamily = New-Object System.Windows.Media.FontFamily($FontsUri, "./#Nunito")
  }
  catch {
    Write-DeploymentLog -Message "Nunito font could not be loaded; falling back to the default font. $($_.Exception.Message)" -Level "WARNING"
  }

  $RootDockPanel = $Window.FindName("RootDockPanel")
  $TitleBarVersionText = $Window.FindName("TitleBarVersionText")
  $TitleBarMinimizeButton = $Window.FindName("TitleBarMinimizeButton")
  $TitleBarMaximizeButton = $Window.FindName("TitleBarMaximizeButton")
  $TitleBarCloseButton = $Window.FindName("TitleBarCloseButton")

  $TitleBarVersionText.Text = "v$AppVersion"

  $script:GuiPlaceholderText = $Window.FindName("PlaceholderText")

  $CompletionModalControls = @{
    Overlay      = $Window.FindName("CompletionModalOverlay")
    IconSuccess  = $Window.FindName("CompletionModalIconSuccess")
    IconWarning  = $Window.FindName("CompletionModalIconWarning")
    TitleText    = $Window.FindName("CompletionModalTitleText")
    CountsPanel  = $Window.FindName("CompletionModalCountsPanel")
    DetailsCard  = $Window.FindName("CompletionModalDetailsCard")
    DetailsPanel = $Window.FindName("CompletionModalDetailsPanel")
  }
  $CompletionModalOkButton = $Window.FindName("CompletionModalOkButton")
  $CompletionModalCopyButton = $Window.FindName("CompletionModalCopyButton")

  $CompletionModalOkButton.Add_Click({
    $CompletionModalControls.Overlay.Visibility = "Collapsed"
  })

  $CompletionModalCopyButton.Add_Click({
    Invoke-GuiCopyCompletionSummary -CopyButton $CompletionModalCopyButton
  })

  # Each screen's own FindName + click-handler wiring lives in its own file; each Initialize-GuiXScreen call returns that screen's Nav Border/Text/Icon triple for the shared nav arrays below, plus (for Windows Setup/Device Details/Asset ID) whatever their one shared Refresh mechanism needs from them. Dot-sourced (". Initialize-...", not a plain call) so each function body runs in Show-MainWindow's own scope instead of a child scope that is torn down the moment the function returns -- a plain call here left every closure created inside it (nav clicks, Select All, etc.) referencing an already-gone scope, surfacing as "Cannot bind argument ... because it is null" the instant any of them fired; confirmed both the failure and the fix with a real, off-screen, simulated-click end-to-end run of this exact code.
  $ApplicationsScreen = . Initialize-GuiApplicationsScreen -Window $Window -CompletionModalControls $CompletionModalControls

  # Employee mode shows only the Applications tab, per instruction (Windows Setup, Asset ID) and by extension (Device Details, Deployment Validation, Deployment Logs, Temp Cleanup are all IT-facing diagnostic/maintenance/config tools, not application-installation-relevant). None of their Initialize-GuiXScreen functions are called at all in this mode -- their nav items are hidden directly here rather than left wired-but-invisible, since they were never asked to render or accept clicks in the first place. If/else branches are not their own scope in PowerShell (unlike function calls), so the variables assigned inside the "else" branch below are ordinary Show-MainWindow locals, not at risk of the same torn-down-scope problem dot-sourcing works around above.
  if ($script:DeploymentMode -eq "Employee") {
    foreach ($HiddenNavName in @("NavWindowsSetup", "NavDeviceDetails", "NavAssetId", "NavDeploymentLogs", "NavDeploymentValidation", "NavTempCleanup")) {
      $HiddenNav = $Window.FindName($HiddenNavName)

      if ($null -ne $HiddenNav) {
        $HiddenNav.Visibility = "Collapsed"
      }
    }

    $script:GuiNavBorders = @($ApplicationsScreen.NavBorder)
    $script:GuiNavTexts = @($ApplicationsScreen.NavText)
    $script:GuiNavIcons = @($ApplicationsScreen.NavIcon)
  }
  else {
    $WindowsSetupScreen = . Initialize-GuiWindowsSetupScreen -Window $Window
    $DeviceDetailsScreen = . Initialize-GuiDeviceDetailsScreen -Window $Window
    $AssetIdScreen = . Initialize-GuiAssetIdScreen -Window $Window
    $DeploymentLogsScreen = . Initialize-GuiDeploymentLogsScreen -Window $Window
    $DeploymentValidationScreen = . Initialize-GuiDeploymentValidationScreen -Window $Window
    $TempCleanupScreen = . Initialize-GuiTempCleanupScreen -Window $Window -CompletionModalControls $CompletionModalControls

    $script:GuiNavBorders = @($ApplicationsScreen.NavBorder, $WindowsSetupScreen.NavBorder, $DeviceDetailsScreen.NavBorder, $AssetIdScreen.NavBorder, $DeploymentLogsScreen.NavBorder, $DeploymentValidationScreen.NavBorder, $TempCleanupScreen.NavBorder)
    $script:GuiNavTexts = @($ApplicationsScreen.NavText, $WindowsSetupScreen.NavText, $DeviceDetailsScreen.NavText, $AssetIdScreen.NavText, $DeploymentLogsScreen.NavText, $DeploymentValidationScreen.NavText, $TempCleanupScreen.NavText)
    $script:GuiNavIcons = @($ApplicationsScreen.NavIcon, $WindowsSetupScreen.NavIcon, $DeviceDetailsScreen.NavIcon, $AssetIdScreen.NavIcon, $DeploymentLogsScreen.NavIcon, $DeploymentValidationScreen.NavIcon, $TempCleanupScreen.NavIcon)

    # Windows Setup, Device Details, and Asset ID share one background-loaded device report (Start-GuiWindowsConfigLoad/Invoke-GuiWindowsConfigurationRefresh, GuiWindowsConfigShared.ps1); each screen's own Refresh button runs the exact same full refresh, wired here since it spans controls owned by all three screens rather than belonging to just one of them.
    $script:GuiWindowsConfigLoaded = $false
    $script:GuiRefreshWindowsConfigButtons = @($WindowsSetupScreen.RefreshButton, $DeviceDetailsScreen.RefreshButton, $AssetIdScreen.RefreshButton)

    $WindowsSetupScreen.RefreshButton.Add_Click({
      try {
        Invoke-GuiWindowsConfigurationRefresh -DeviceFields $DeviceDetailsScreen.DeviceFields -CurrentNameText $WindowsSetupScreen.CurrentNameText -LocalUsersListPanel $WindowsSetupScreen.LocalUsersListPanel -CurrentPluggedInText $WindowsSetupScreen.CurrentPluggedInText -CurrentBatteryText $WindowsSetupScreen.CurrentBatteryText -NavAssetId $AssetIdScreen.NavAssetId -AssetIdFieldTextBoxes $AssetIdScreen.FieldTextBoxes
      }
      catch {
        Show-GuiDialog -Title "Error" -Icon Warning -Message "Refresh error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
      }
    })

    $DeviceDetailsScreen.RefreshButton.Add_Click({
      try {
        Invoke-GuiWindowsConfigurationRefresh -DeviceFields $DeviceDetailsScreen.DeviceFields -CurrentNameText $WindowsSetupScreen.CurrentNameText -LocalUsersListPanel $WindowsSetupScreen.LocalUsersListPanel -CurrentPluggedInText $WindowsSetupScreen.CurrentPluggedInText -CurrentBatteryText $WindowsSetupScreen.CurrentBatteryText -NavAssetId $AssetIdScreen.NavAssetId -AssetIdFieldTextBoxes $AssetIdScreen.FieldTextBoxes
      }
      catch {
        Show-GuiDialog -Title "Error" -Icon Warning -Message "Refresh error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
      }
    })

    $AssetIdScreen.RefreshButton.Add_Click({
      try {
        Invoke-GuiWindowsConfigurationRefresh -DeviceFields $DeviceDetailsScreen.DeviceFields -CurrentNameText $WindowsSetupScreen.CurrentNameText -LocalUsersListPanel $WindowsSetupScreen.LocalUsersListPanel -CurrentPluggedInText $WindowsSetupScreen.CurrentPluggedInText -CurrentBatteryText $WindowsSetupScreen.CurrentBatteryText -NavAssetId $AssetIdScreen.NavAssetId -AssetIdFieldTextBoxes $AssetIdScreen.FieldTextBoxes
      }
      catch {
        Show-GuiDialog -Title "Error" -Icon Warning -Message "Refresh error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
      }
    })
  }

  Update-GuiSystemInfoBar -Window $Window

  $TitleBarMinimizeButton.Add_MouseLeftButtonUp({
    try {
      [System.Windows.SystemCommands]::MinimizeWindow($Window)
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Minimize error: $($_.Exception.Message)"
    }
  })

  $TitleBarMaximizeButton.Add_MouseLeftButtonUp({
    try {
      if ($Window.WindowState -eq [System.Windows.WindowState]::Maximized) {
        [System.Windows.SystemCommands]::RestoreWindow($Window)
      }
      else {
        [System.Windows.SystemCommands]::MaximizeWindow($Window)
      }
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Maximize error: $($_.Exception.Message)"
    }
  })

  $TitleBarCloseButton.Add_MouseLeftButtonUp({
    try {
      [System.Windows.SystemCommands]::CloseWindow($Window)
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Close error: $($_.Exception.Message)"
    }
  })

  # WindowChrome's known maximize-clipping bug: without this, the maximized window renders a few pixels past the monitor's working area on every edge. Doubling the resize-border thickness as the maximized-state margin was empirically verified to correct it in this environment.
  $Window.Add_StateChanged({
    if ($Window.WindowState -eq [System.Windows.WindowState]::Maximized) {
      $ResizeBorder = [System.Windows.SystemParameters]::WindowResizeBorderThickness
      $RootDockPanel.Margin = New-Object System.Windows.Thickness(($ResizeBorder.Left * 2), ($ResizeBorder.Top * 2), ($ResizeBorder.Right * 2), ($ResizeBorder.Bottom * 2))
    }
    else {
      $RootDockPanel.Margin = New-Object System.Windows.Thickness(0)
    }
  })

  $Window.Add_Closing({
    if ($script:GuiQueueRunning) {
      $_.Cancel = $true
      Show-GuiDialog -Title "Please Wait" -Icon Warning -Message "An install or uninstall is still running. Please wait for it to finish before closing."
      return
    }

    if ($script:GuiDeleteOnClose) {
      $Confirmation = Show-GuiDialog -Title "Remove IT Deployment Tool" -Icon Warning -Buttons YesNo `
        -Message "This will permanently delete the IT Deployment Tool from this device (scripts, config, downloaded installer packages, and logs). Continue?"

      if ($Confirmation -ne "Yes") {
        $_.Cancel = $true
        return
      }

      Start-GuiSelfDeleteOnExit
    }
  })

  [void]$Window.ShowDialog()

  Complete-DeploymentLog
}
