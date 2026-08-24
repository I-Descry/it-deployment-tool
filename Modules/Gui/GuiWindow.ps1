# ============================================================
# GUI WINDOW (main window shell: navigation, system info bar, entry point)
# ============================================================
# Per-screen logic lives in GuiIcons.ps1, GuiApplicationsScreen.ps1,
# GuiDeploymentValidationScreen.ps1, GuiDeploymentLogsScreen.ps1, and
# GuiWindowsConfigScreen.ps1 (all loaded before this file). This file ties
# them together: cross-screen navigation, the system info bar, and the
# Show-MainWindow entry point that wires every control.

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

  # The checks that follow this call run synchronously on the UI thread and
  # can take the better part of a second (CIM/BIOS queries, powercfg.exe).
  # Forcing a Render-priority dispatch here flushes the "Loading..." text to
  # screen first, so the tab switch itself feels instant instead of frozen.
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
    $NavBorder.Background = $null
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

  if ($ScreenName -eq "Applications") {
    $script:GuiApplicationsToolbar.Visibility = "Visible"
    $script:GuiApplicationsScrollViewer.Visibility = "Visible"
    $script:GuiDeploymentValidationToolbar.Visibility = "Collapsed"
    $script:GuiDeploymentValidationScrollViewer.Visibility = "Collapsed"
    $script:GuiDeploymentLogsToolbar.Visibility = "Collapsed"
    $script:GuiDeploymentLogsContent.Visibility = "Collapsed"
    $script:GuiWindowsConfigToolbar.Visibility = "Collapsed"
    $script:GuiWindowsConfigScrollViewer.Visibility = "Collapsed"
    $script:GuiPlaceholderText.Visibility = "Collapsed"

    Start-GuiFadeIn -Element $script:GuiApplicationsScrollViewer
  }
  elseif ($ScreenName -eq "Deployment Validation") {
    $script:GuiApplicationsToolbar.Visibility = "Collapsed"
    $script:GuiApplicationsScrollViewer.Visibility = "Collapsed"
    $script:GuiDeploymentValidationToolbar.Visibility = "Visible"
    $script:GuiDeploymentValidationScrollViewer.Visibility = "Visible"
    $script:GuiDeploymentLogsToolbar.Visibility = "Collapsed"
    $script:GuiDeploymentLogsContent.Visibility = "Collapsed"
    $script:GuiWindowsConfigToolbar.Visibility = "Collapsed"
    $script:GuiWindowsConfigScrollViewer.Visibility = "Collapsed"
    $script:GuiPlaceholderText.Visibility = "Collapsed"

    if (-not $script:GuiDeploymentValidationLoaded) {
      $script:GuiDeploymentValidationLoaded = $true
      Start-GuiDeploymentValidationLoad -ValidationPanel $script:GuiDeploymentValidationPanel -SummaryText $script:GuiValidationSummaryText -RerunButton $script:GuiRerunValidationButton
    }

    Start-GuiFadeIn -Element $script:GuiDeploymentValidationScrollViewer
  }
  elseif ($ScreenName -eq "Deployment Logs") {
    $script:GuiApplicationsToolbar.Visibility = "Collapsed"
    $script:GuiApplicationsScrollViewer.Visibility = "Collapsed"
    $script:GuiDeploymentValidationToolbar.Visibility = "Collapsed"
    $script:GuiDeploymentValidationScrollViewer.Visibility = "Collapsed"
    $script:GuiDeploymentLogsToolbar.Visibility = "Visible"
    $script:GuiDeploymentLogsContent.Visibility = "Visible"
    $script:GuiWindowsConfigToolbar.Visibility = "Collapsed"
    $script:GuiWindowsConfigScrollViewer.Visibility = "Collapsed"
    $script:GuiPlaceholderText.Visibility = "Collapsed"

    if (-not $script:GuiDeploymentLogsLoaded) {
      $script:GuiDeploymentLogsLoaded = $true
      Update-GuiLogsList -ListPanel $script:GuiDeploymentLogsPanel -ContentTextBox $script:GuiLogContentTextBox -NameText $script:GuiSelectedLogNameText
    }

    Start-GuiFadeIn -Element $script:GuiDeploymentLogsContent
  }
  elseif ($ScreenName -eq "Windows Configuration") {
    $script:GuiApplicationsToolbar.Visibility = "Collapsed"
    $script:GuiApplicationsScrollViewer.Visibility = "Collapsed"
    $script:GuiDeploymentValidationToolbar.Visibility = "Collapsed"
    $script:GuiDeploymentValidationScrollViewer.Visibility = "Collapsed"
    $script:GuiDeploymentLogsToolbar.Visibility = "Collapsed"
    $script:GuiDeploymentLogsContent.Visibility = "Collapsed"
    $script:GuiWindowsConfigToolbar.Visibility = "Visible"
    $script:GuiWindowsConfigScrollViewer.Visibility = "Visible"
    $script:GuiPlaceholderText.Visibility = "Collapsed"

    if (-not $script:GuiWindowsConfigLoaded) {
      $script:GuiWindowsConfigLoaded = $true

      # Runs the CIM/BIOS/powercfg queries on a background runspace (the same
      # pattern used for install/uninstall queues) so this first load never
      # blocks the UI thread. Start-GuiFadeIn runs once the data actually
      # arrives, inside Start-GuiWindowsConfigLoad's own completion handler,
      # rather than immediately below like the other screens.
      Start-GuiWindowsConfigLoad -DeviceFields $script:GuiWindowsConfigDeviceFields -CurrentNameText $script:GuiCurrentComputerNameText -LocalUsersListPanel $script:GuiLocalUsersListPanel -CurrentPluggedInText $script:GuiCurrentPluggedInText -CurrentBatteryText $script:GuiCurrentBatteryText -RefreshButton $script:GuiRefreshWindowsConfigButton -ScrollViewer $script:GuiWindowsConfigScrollViewer
    }
    else {
      Start-GuiFadeIn -Element $script:GuiWindowsConfigScrollViewer
    }
  }
  else {
    $script:GuiApplicationsToolbar.Visibility = "Collapsed"
    $script:GuiApplicationsScrollViewer.Visibility = "Collapsed"
    $script:GuiDeploymentValidationToolbar.Visibility = "Collapsed"
    $script:GuiDeploymentValidationScrollViewer.Visibility = "Collapsed"
    $script:GuiDeploymentLogsToolbar.Visibility = "Collapsed"
    $script:GuiDeploymentLogsContent.Visibility = "Collapsed"
    $script:GuiWindowsConfigToolbar.Visibility = "Collapsed"
    $script:GuiWindowsConfigScrollViewer.Visibility = "Collapsed"
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

function Show-MainWindow {
  Add-Type -AssemblyName PresentationFramework

  $script:GuiSessionStartTime = Get-Date

  Initialize-DeploymentLog -Version $AppVersion

  Initialize-Applications | Out-Null
  Update-ApplicationInstallationStatus

  $XamlPath = Join-Path $script:ITDeploymentToolRoot "Modules\Gui\MainWindow.xaml"

  [xml]$WindowXaml = Get-Content -LiteralPath $XamlPath -Raw

  $Reader = New-Object System.Xml.XmlNodeReader $WindowXaml
  $Window = [Windows.Markup.XamlReader]::Load($Reader)

  # Nunito is bundled as a variable font rather than installed system-wide,
  # since this tool is copied directly to technician machines rather than
  # installed. Loaded via an absolute folder URI (not a relative XAML path)
  # because XamlReader.Load has no base URI to resolve a relative FontFamily
  # reference against here -- every other path in this app already uses
  # $script:ITDeploymentToolRoot for the same reason. Falls back to the
  # XAML's own Segoe UI default if the font file is ever missing (e.g. not
  # yet copied to this machine), rather than failing to start.
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
  $DeploymentValidationPanel = $Window.FindName("DeploymentValidationPanel")
  $ValidationSummaryText = $Window.FindName("ValidationSummaryText")
  $RerunValidationButton = $Window.FindName("RerunValidationButton")
  $DeploymentLogsPanel = $Window.FindName("DeploymentLogsPanel")
  $LogContentTextBox = $Window.FindName("LogContentTextBox")
  $SelectedLogNameText = $Window.FindName("SelectedLogNameText")
  $RefreshLogsButton = $Window.FindName("RefreshLogsButton")
  $OpenLogsFolderButton = $Window.FindName("OpenLogsFolderButton")
  $RefreshWindowsConfigButton = $Window.FindName("RefreshWindowsConfigButton")
  $CurrentComputerNameText = $Window.FindName("CurrentComputerNameText")
  $NewComputerNameTextBox = $Window.FindName("NewComputerNameTextBox")
  $RenameComputerButton = $Window.FindName("RenameComputerButton")
  $LocalUsersListPanel = $Window.FindName("LocalUsersListPanel")
  $NewUserNameTextBox = $Window.FindName("NewUserNameTextBox")
  $NewUserFullNameTextBox = $Window.FindName("NewUserFullNameTextBox")
  $NewUserPasswordBox = $Window.FindName("NewUserPasswordBox")
  $NewUserConfirmPasswordBox = $Window.FindName("NewUserConfirmPasswordBox")
  $CreateUserButton = $Window.FindName("CreateUserButton")
  $CurrentPluggedInText = $Window.FindName("CurrentPluggedInText")
  $CurrentBatteryText = $Window.FindName("CurrentBatteryText")
  $PluggedInMinutesTextBox = $Window.FindName("PluggedInMinutesTextBox")
  $BatteryMinutesTextBox = $Window.FindName("BatteryMinutesTextBox")
  $ApplyPowerSettingsButton = $Window.FindName("ApplyPowerSettingsButton")

  $WindowsConfigDeviceFields = @{
    ComputerName    = $Window.FindName("DeviceComputerNameText")
    Manufacturer    = $Window.FindName("DeviceManufacturerText")
    Model           = $Window.FindName("DeviceModelText")
    SerialNumber    = $Window.FindName("DeviceSerialNumberText")
    NetworkType     = $Window.FindName("DeviceNetworkTypeText")
    DomainWorkgroup = $Window.FindName("DeviceDomainWorkgroupText")
    OSEdition       = $Window.FindName("DeviceOSEditionText")
    OSVersion       = $Window.FindName("DeviceOSVersionText")
    OSBuildNumber   = $Window.FindName("DeviceOSBuildNumberText")
    OSArchitecture  = $Window.FindName("DeviceOSArchitectureText")
    LoggedUser      = $Window.FindName("DeviceLoggedUserText")
    AdminStatus     = $Window.FindName("DeviceAdminStatusText")
    PowerPlan       = $Window.FindName("DevicePowerPlanText")
    Sleep           = $Window.FindName("DeviceSleepText")
  }

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

  $InitialTimeouts = Get-CurrentSleepTimeoutMinutes
  $PluggedInMinutesTextBox.Text = [string]$InitialTimeouts.PluggedInMinutes
  $BatteryMinutesTextBox.Text = [string]$InitialTimeouts.BatteryMinutes

  Update-GuiApplicationGrid -GridPanel $AppGridPanel
  Update-GuiSelectedCount -CountText $SelectedCountText
  Update-GuiSystemInfoBar -Window $Window

  $SelectAllButton.Add_Click({
    try {
      Select-AllApplications
      Update-GuiApplicationGrid -GridPanel $AppGridPanel
      Update-GuiSelectedCount -CountText $SelectedCountText
    }
    catch {
      [System.Windows.MessageBox]::Show("Select All error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
  })

  $SelectRecommendedButton.Add_Click({
    try {
      Select-RecommendedApplications | Out-Null
      Update-GuiApplicationGrid -GridPanel $AppGridPanel
      Update-GuiSelectedCount -CountText $SelectedCountText
    }
    catch {
      [System.Windows.MessageBox]::Show("Select Recommended error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
  })

  $ClearAllButton.Add_Click({
    try {
      Clear-AllApplications
      Update-GuiApplicationGrid -GridPanel $AppGridPanel
      Update-GuiSelectedCount -CountText $SelectedCountText
    }
    catch {
      [System.Windows.MessageBox]::Show("Clear All error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
  })

  $InstallSelectedButton.Add_Click({
    try {
      Invoke-GuiInstallQueue -GridPanel $AppGridPanel -CountText $SelectedCountText -InstallButton $InstallSelectedButton -UninstallButton $UninstallSelectedButton `
        -CancelButton $CancelQueueButton -QueueProgressPanel $QueueProgressPanel -QueueProgressText $QueueProgressText -QueueProgressBar $QueueProgressBar `
        -ModalControls $CompletionModalControls
    }
    catch {
      [System.Windows.MessageBox]::Show("Install error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
  })

  $UninstallSelectedButton.Add_Click({
    try {
      Invoke-GuiUninstallQueue -GridPanel $AppGridPanel -CountText $SelectedCountText -InstallButton $InstallSelectedButton -UninstallButton $UninstallSelectedButton `
        -CancelButton $CancelQueueButton -QueueProgressPanel $QueueProgressPanel -QueueProgressText $QueueProgressText -QueueProgressBar $QueueProgressBar `
        -ModalControls $CompletionModalControls
    }
    catch {
      [System.Windows.MessageBox]::Show("Uninstall error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
  })

  $CancelQueueButton.Add_Click({
    try {
      $CancelQueueButton.IsEnabled = $false
      $CancelQueueButton.Content = "Cancelling..."
      $script:GuiQueueCancelQueue.Enqueue($true)
    }
    catch {
      [System.Windows.MessageBox]::Show("Cancel error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
  })

  $CompletionModalOkButton.Add_Click({
    $CompletionModalControls.Overlay.Visibility = "Collapsed"
  })

  $RerunValidationButton.Add_Click({
    try {
      Start-GuiDeploymentValidationLoad -ValidationPanel $DeploymentValidationPanel -SummaryText $ValidationSummaryText -RerunButton $RerunValidationButton
    }
    catch {
      [System.Windows.MessageBox]::Show("Deployment validation error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
  })

  $RefreshLogsButton.Add_Click({
    try {
      Update-GuiLogsList -ListPanel $DeploymentLogsPanel -ContentTextBox $LogContentTextBox -NameText $SelectedLogNameText
    }
    catch {
      [System.Windows.MessageBox]::Show("Refresh error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
  })

  $OpenLogsFolderButton.Add_Click({
    try {
      Open-DeploymentLogsFolder
    }
    catch {
      [System.Windows.MessageBox]::Show("Unable to open the Logs folder: $($_.Exception.Message)")
    }
  })

  $RefreshWindowsConfigButton.Add_Click({
    try {
      Invoke-GuiWindowsConfigurationRefresh -DeviceFields $WindowsConfigDeviceFields -CurrentNameText $CurrentComputerNameText -LocalUsersListPanel $LocalUsersListPanel -CurrentPluggedInText $CurrentPluggedInText -CurrentBatteryText $CurrentBatteryText
    }
    catch {
      [System.Windows.MessageBox]::Show("Refresh error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
  })

  $RenameComputerButton.Add_Click({
    try {
      Invoke-GuiComputerRename -NewNameTextBox $NewComputerNameTextBox -CurrentNameText $CurrentComputerNameText
    }
    catch {
      [System.Windows.MessageBox]::Show("Rename error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
  })

  $CreateUserButton.Add_Click({
    try {
      Invoke-GuiLocalUserCreation -UserNameTextBox $NewUserNameTextBox -FullNameTextBox $NewUserFullNameTextBox -PasswordBox $NewUserPasswordBox -ConfirmPasswordBox $NewUserConfirmPasswordBox -ListPanel $LocalUsersListPanel
    }
    catch {
      [System.Windows.MessageBox]::Show("Create user error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
  })

  $ApplyPowerSettingsButton.Add_Click({
    try {
      Invoke-GuiPowerSettingsApply -PluggedInMinutesTextBox $PluggedInMinutesTextBox -BatteryMinutesTextBox $BatteryMinutesTextBox -CurrentPluggedInText $CurrentPluggedInText -CurrentBatteryText $CurrentBatteryText
    }
    catch {
      [System.Windows.MessageBox]::Show("Apply power settings error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
  })

  $NavApplications = $Window.FindName("NavApplications")
  $NavApplicationsText = $Window.FindName("NavApplicationsText")
  $NavApplicationsIcon = $Window.FindName("NavApplicationsIcon")
  $NavWindowsConfig = $Window.FindName("NavWindowsConfig")
  $NavWindowsConfigText = $Window.FindName("NavWindowsConfigText")
  $NavWindowsConfigIcon = $Window.FindName("NavWindowsConfigIcon")
  $NavDeploymentLogs = $Window.FindName("NavDeploymentLogs")
  $NavDeploymentLogsText = $Window.FindName("NavDeploymentLogsText")
  $NavDeploymentLogsIcon = $Window.FindName("NavDeploymentLogsIcon")
  $NavDeploymentValidation = $Window.FindName("NavDeploymentValidation")
  $NavDeploymentValidationText = $Window.FindName("NavDeploymentValidationText")
  $NavDeploymentValidationIcon = $Window.FindName("NavDeploymentValidationIcon")

  $script:GuiQueueRunning = $false
  $script:GuiSelectedCountText = $SelectedCountText
  $script:GuiDeploymentValidationLoaded = $false
  $script:GuiDeploymentLogsLoaded = $false
  $script:GuiWindowsConfigLoaded = $false
  $script:GuiNavBorders = @($NavApplications, $NavWindowsConfig, $NavDeploymentLogs, $NavDeploymentValidation)
  $script:GuiNavTexts = @($NavApplicationsText, $NavWindowsConfigText, $NavDeploymentLogsText, $NavDeploymentValidationText)
  $script:GuiNavIcons = @($NavApplicationsIcon, $NavWindowsConfigIcon, $NavDeploymentLogsIcon, $NavDeploymentValidationIcon)
  $script:GuiApplicationsToolbar = $Window.FindName("ApplicationsToolbar")
  $script:GuiApplicationsScrollViewer = $Window.FindName("ApplicationsScrollViewer")
  $script:GuiPlaceholderText = $Window.FindName("PlaceholderText")
  $script:GuiDeploymentValidationToolbar = $Window.FindName("DeploymentValidationToolbar")
  $script:GuiDeploymentValidationScrollViewer = $Window.FindName("DeploymentValidationScrollViewer")
  $script:GuiDeploymentValidationPanel = $DeploymentValidationPanel
  $script:GuiValidationSummaryText = $ValidationSummaryText
  $script:GuiRerunValidationButton = $RerunValidationButton
  $script:GuiRefreshWindowsConfigButton = $RefreshWindowsConfigButton
  $script:GuiDeploymentLogsToolbar = $Window.FindName("DeploymentLogsToolbar")
  $script:GuiDeploymentLogsContent = $Window.FindName("DeploymentLogsContent")
  $script:GuiDeploymentLogsPanel = $DeploymentLogsPanel
  $script:GuiLogContentTextBox = $LogContentTextBox
  $script:GuiSelectedLogNameText = $SelectedLogNameText
  $script:GuiWindowsConfigToolbar = $Window.FindName("WindowsConfigToolbar")
  $script:GuiWindowsConfigScrollViewer = $Window.FindName("WindowsConfigScrollViewer")
  $script:GuiWindowsConfigDeviceFields = $WindowsConfigDeviceFields
  $script:GuiCurrentComputerNameText = $CurrentComputerNameText
  $script:GuiLocalUsersListPanel = $LocalUsersListPanel
  $script:GuiCurrentPluggedInText = $CurrentPluggedInText
  $script:GuiCurrentBatteryText = $CurrentBatteryText

  $NavApplications.Add_MouseLeftButtonUp({
    try {
      Switch-GuiScreen -ScreenName "Applications" -ActiveBorder $NavApplications -ActiveText $NavApplicationsText -ActiveIcon $NavApplicationsIcon
    }
    catch {
      [System.Windows.MessageBox]::Show("Navigation error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
  })

  $NavWindowsConfig.Add_MouseLeftButtonUp({
    try {
      Switch-GuiScreen -ScreenName "Windows Configuration" -ActiveBorder $NavWindowsConfig -ActiveText $NavWindowsConfigText -ActiveIcon $NavWindowsConfigIcon
    }
    catch {
      [System.Windows.MessageBox]::Show("Navigation error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
  })

  $NavDeploymentLogs.Add_MouseLeftButtonUp({
    try {
      Switch-GuiScreen -ScreenName "Deployment Logs" -ActiveBorder $NavDeploymentLogs -ActiveText $NavDeploymentLogsText -ActiveIcon $NavDeploymentLogsIcon
    }
    catch {
      [System.Windows.MessageBox]::Show("Navigation error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
  })

  $NavDeploymentValidation.Add_MouseLeftButtonUp({
    try {
      Switch-GuiScreen -ScreenName "Deployment Validation" -ActiveBorder $NavDeploymentValidation -ActiveText $NavDeploymentValidationText -ActiveIcon $NavDeploymentValidationIcon
    }
    catch {
      [System.Windows.MessageBox]::Show("Navigation error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
  })

  $TitleBarMinimizeButton.Add_MouseLeftButtonUp({
    try {
      [System.Windows.SystemCommands]::MinimizeWindow($Window)
    }
    catch {
      [System.Windows.MessageBox]::Show("Minimize error: $($_.Exception.Message)")
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
      [System.Windows.MessageBox]::Show("Maximize error: $($_.Exception.Message)")
    }
  })

  $TitleBarCloseButton.Add_MouseLeftButtonUp({
    try {
      [System.Windows.SystemCommands]::CloseWindow($Window)
    }
    catch {
      [System.Windows.MessageBox]::Show("Close error: $($_.Exception.Message)")
    }
  })

  # WindowChrome's known maximize-clipping bug: without this, the maximized
  # window renders a few pixels past the monitor's working area on every
  # edge. Doubling the resize-border thickness as the maximized-state margin
  # was empirically verified to correct it in this environment.
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
      [System.Windows.MessageBox]::Show("An install or uninstall is still running. Please wait for it to finish before closing.")
    }
  })

  [void]$Window.ShowDialog()

  Complete-DeploymentLog
}
