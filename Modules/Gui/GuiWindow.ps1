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
  $script:GuiPlaceholderText.Visibility = "Collapsed"

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
  $RefreshWindowsSetupButton = $Window.FindName("RefreshWindowsSetupButton")
  $RefreshDeviceDetailsButton = $Window.FindName("RefreshDeviceDetailsButton")
  $CopyDeviceDetailsButton = $Window.FindName("CopyDeviceDetailsButton")
  $CurrentComputerNameText = $Window.FindName("CurrentComputerNameText")
  $NewComputerNameTextBox = $Window.FindName("NewComputerNameTextBox")
  $RestartLaterOption = $Window.FindName("RestartLaterOption")
  $RestartLaterOptionText = $Window.FindName("RestartLaterOptionText")
  $RestartNowOption = $Window.FindName("RestartNowOption")
  $RestartNowOptionText = $Window.FindName("RestartNowOptionText")
  $RenameComputerButton = $Window.FindName("RenameComputerButton")
  $LocalUsersListPanel = $Window.FindName("LocalUsersListPanel")
  $NewUserNameTextBox = $Window.FindName("NewUserNameTextBox")
  $NewUserFullNameTextBox = $Window.FindName("NewUserFullNameTextBox")
  $SetPasswordOption = $Window.FindName("SetPasswordOption")
  $SetPasswordOptionText = $Window.FindName("SetPasswordOptionText")
  $NoPasswordOption = $Window.FindName("NoPasswordOption")
  $NoPasswordOptionText = $Window.FindName("NoPasswordOptionText")
  $NewUserPasswordFieldsPanel = $Window.FindName("NewUserPasswordFieldsPanel")
  $NoPasswordNoticeBox = $Window.FindName("NoPasswordNoticeBox")
  $NewUserPasswordBox = $Window.FindName("NewUserPasswordBox")
  $NewUserConfirmPasswordBox = $Window.FindName("NewUserConfirmPasswordBox")
  $CreateUserButton = $Window.FindName("CreateUserButton")
  $CurrentPluggedInText = $Window.FindName("CurrentPluggedInText")
  $CurrentBatteryText = $Window.FindName("CurrentBatteryText")
  $PluggedInMinutesTextBox = $Window.FindName("PluggedInMinutesTextBox")
  $BatteryMinutesTextBox = $Window.FindName("BatteryMinutesTextBox")
  $ApplyPowerSettingsButton = $Window.FindName("ApplyPowerSettingsButton")

  $NavAssetId = $Window.FindName("NavAssetId")
  $NavAssetIdText = $Window.FindName("NavAssetIdText")
  $NavAssetIdIcon = $Window.FindName("NavAssetIdIcon")
  $AssetIdToolbar = $Window.FindName("AssetIdToolbar")
  $RefreshAssetIdButton = $Window.FindName("RefreshAssetIdButton")
  $AssetIdScrollViewer = $Window.FindName("AssetIdScrollViewer")
  $AssetOwnerNameTextBox = $Window.FindName("AssetOwnerNameTextBox")
  $AssetDepartmentTextBox = $Window.FindName("AssetDepartmentTextBox")
  $AssetLocationTextBox = $Window.FindName("AssetLocationTextBox")
  $AssetPhoneNumberTextBox = $Window.FindName("AssetPhoneNumberTextBox")
  $AssetOwnerPositionTextBox = $Window.FindName("AssetOwnerPositionTextBox")
  $AssetPurchaseDateTextBox = $Window.FindName("AssetPurchaseDateTextBox")
  $AssetLastInventoriedTextBox = $Window.FindName("AssetLastInventoriedTextBox")
  $AssetWarrantyEndTextBox = $Window.FindName("AssetWarrantyEndTextBox")
  $AssetWarrantyDurationTextBox = $Window.FindName("AssetWarrantyDurationTextBox")
  $AssetAmountTextBox = $Window.FindName("AssetAmountTextBox")
  $AssetNumberTextBox = $Window.FindName("AssetNumberTextBox")
  $SaveAssetIdButton = $Window.FindName("SaveAssetIdButton")

  $TempCleanupToolbar = $Window.FindName("TempCleanupToolbar")
  $TempCleanupScrollViewer = $Window.FindName("TempCleanupScrollViewer")
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

  # Keyed the same way Get-DeploymentAssetIdFieldNames orders them, so Update-GuiAssetIdFields/Invoke-GuiAssetIdSave can loop instead of repeating each field name by hand.
  $AssetIdFieldTextBoxes = @{
    "OWNERDATA.OWNERNAME"              = $AssetOwnerNameTextBox
    "OWNERDATA.DEPARTMENT"             = $AssetDepartmentTextBox
    "OWNERDATA.LOCATION"               = $AssetLocationTextBox
    "OWNERDATA.PHONE_NUMBER"           = $AssetPhoneNumberTextBox
    "OWNERDATA.OWNERPOSITION"          = $AssetOwnerPositionTextBox
    "USERASSETDATA.PURCHASE_DATE"      = $AssetPurchaseDateTextBox
    "USERASSETDATA.LAST_INVENTORIED"   = $AssetLastInventoriedTextBox
    "USERASSETDATA.WARRANTY_END"       = $AssetWarrantyEndTextBox
    "USERASSETDATA.WARRANTY_DURATION"  = $AssetWarrantyDurationTextBox
    "USERASSETDATA.AMOUNT"             = $AssetAmountTextBox
    "USERASSETDATA.ASSET_NUMBER"       = $AssetNumberTextBox
  }

  $WindowsConfigDeviceFields = @{
    ComputerName         = $Window.FindName("DeviceComputerNameText")
    Manufacturer         = $Window.FindName("DeviceManufacturerText")
    Model                = $Window.FindName("DeviceModelText")
    SerialNumber         = $Window.FindName("DeviceSerialNumberText")
    BiosVersion          = $Window.FindName("DeviceBiosVersionText")
    AssetTag             = $Window.FindName("DeviceAssetTagText")
    NetworkType          = $Window.FindName("DeviceNetworkTypeText")
    IPAddress            = $Window.FindName("DeviceIPAddressText")
    MacAddress           = $Window.FindName("DeviceMacAddressText")
    DomainWorkgroup      = $Window.FindName("DeviceDomainWorkgroupText")
    OSEdition            = $Window.FindName("DeviceOSEditionText")
    OSVersion            = $Window.FindName("DeviceOSVersionText")
    OSBuildNumber        = $Window.FindName("DeviceOSBuildNumberText")
    OSArchitecture       = $Window.FindName("DeviceOSArchitectureText")
    ActivationStatus     = $Window.FindName("DeviceActivationStatusText")
    ActivationStatusPill = $Window.FindName("DeviceActivationStatusPill")
    LastUpdateInstalled  = $Window.FindName("DeviceLastUpdateText")
    Uptime               = $Window.FindName("DeviceUptimeText")
    LoggedUser           = $Window.FindName("DeviceLoggedUserText")
    AdminStatus          = $Window.FindName("DeviceAdminStatusText")
    PowerPlan            = $Window.FindName("DevicePowerPlanText")
    Sleep                = $Window.FindName("DeviceSleepText")
    AdminStatusPill      = $Window.FindName("DeviceAdminStatusPill")
    Processor            = $Window.FindName("DeviceProcessorText")
    Memory               = $Window.FindName("DeviceMemoryText")
    Storage              = $Window.FindName("DeviceStorageText")
    TpmStatus            = $Window.FindName("DeviceTpmStatusText")
    TpmStatusPill        = $Window.FindName("DeviceTpmStatusPill")
    SecureBootStatus     = $Window.FindName("DeviceSecureBootStatusText")
    SecureBootStatusPill = $Window.FindName("DeviceSecureBootStatusPill")
    BatteryHealth        = $Window.FindName("DeviceBatteryHealthText")
    AntivirusStatus      = $Window.FindName("DeviceAntivirusStatusText")
    FirewallStatus       = $Window.FindName("DeviceFirewallStatusText")
    FirewallStatusPill   = $Window.FindName("DeviceFirewallStatusPill")
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
  $CompletionModalCopyButton = $Window.FindName("CompletionModalCopyButton")

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

  $CompletionModalOkButton.Add_Click({
    $CompletionModalControls.Overlay.Visibility = "Collapsed"
  })

  $CompletionModalCopyButton.Add_Click({
    Invoke-GuiCopyCompletionSummary -CopyButton $CompletionModalCopyButton
  })

  $RerunValidationButton.Add_Click({
    try {
      Start-GuiDeploymentValidationLoad -ValidationPanel $DeploymentValidationPanel -SummaryText $ValidationSummaryText -RerunButton $RerunValidationButton
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Deployment validation error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $RefreshLogsButton.Add_Click({
    try {
      Update-GuiLogsList -ListPanel $DeploymentLogsPanel -ContentTextBox $LogContentTextBox -NameText $SelectedLogNameText
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Refresh error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $OpenLogsFolderButton.Add_Click({
    try {
      Open-DeploymentLogsFolder
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Unable to open the Logs folder: $($_.Exception.Message)"
    }
  })

  # Windows Setup, Device Details, and Asset ID are three screens over one shared data load, so all three Refresh buttons run the same full refresh.
  $RefreshWindowsSetupButton.Add_Click({
    try {
      Invoke-GuiWindowsConfigurationRefresh -DeviceFields $WindowsConfigDeviceFields -CurrentNameText $CurrentComputerNameText -LocalUsersListPanel $LocalUsersListPanel -CurrentPluggedInText $CurrentPluggedInText -CurrentBatteryText $CurrentBatteryText -NavAssetId $NavAssetId -AssetIdFieldTextBoxes $AssetIdFieldTextBoxes
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Refresh error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $RefreshDeviceDetailsButton.Add_Click({
    try {
      Invoke-GuiWindowsConfigurationRefresh -DeviceFields $WindowsConfigDeviceFields -CurrentNameText $CurrentComputerNameText -LocalUsersListPanel $LocalUsersListPanel -CurrentPluggedInText $CurrentPluggedInText -CurrentBatteryText $CurrentBatteryText -NavAssetId $NavAssetId -AssetIdFieldTextBoxes $AssetIdFieldTextBoxes
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Refresh error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $RefreshAssetIdButton.Add_Click({
    try {
      Invoke-GuiWindowsConfigurationRefresh -DeviceFields $WindowsConfigDeviceFields -CurrentNameText $CurrentComputerNameText -LocalUsersListPanel $LocalUsersListPanel -CurrentPluggedInText $CurrentPluggedInText -CurrentBatteryText $CurrentBatteryText -NavAssetId $NavAssetId -AssetIdFieldTextBoxes $AssetIdFieldTextBoxes
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Refresh error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $CopyDeviceDetailsButton.Add_Click({
    try {
      Invoke-GuiCopyDeviceDetails -DeviceFields $WindowsConfigDeviceFields -CopyButton $CopyDeviceDetailsButton
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Copy device details error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

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

  # Defaults to Later (today's existing rename behavior) -- Restart Now is always an explicit choice, never the default, since it restarts the machine immediately.
  $script:GuiRenameRestartNow = $false

  $RestartLaterOption.Add_MouseLeftButtonUp({
    try {
      Set-GuiRenameRestartChoice -RestartNow $false -LaterOption $RestartLaterOption -LaterOptionText $RestartLaterOptionText -NowOption $RestartNowOption -NowOptionText $RestartNowOptionText
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Restart choice error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $RestartNowOption.Add_MouseLeftButtonUp({
    try {
      Set-GuiRenameRestartChoice -RestartNow $true -LaterOption $RestartLaterOption -LaterOptionText $RestartLaterOptionText -NowOption $RestartNowOption -NowOptionText $RestartNowOptionText
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Restart choice error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $RenameComputerButton.Add_Click({
    try {
      Invoke-GuiComputerRename -NewNameTextBox $NewComputerNameTextBox -CurrentNameText $CurrentComputerNameText -RestartNow $script:GuiRenameRestartNow
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Rename error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  # Defaults to Set Password (today's existing behavior) -- No Password is always an explicit choice, never the default, since a blank-password local account is an unusual security posture.
  $script:GuiCreateUserNoPassword = $false

  $SetPasswordOption.Add_MouseLeftButtonUp({
    try {
      Set-GuiCreateUserPasswordChoice -NoPassword $false -SetOption $SetPasswordOption -SetOptionText $SetPasswordOptionText -NoPasswordOption $NoPasswordOption -NoPasswordOptionText $NoPasswordOptionText -PasswordFieldsPanel $NewUserPasswordFieldsPanel -NoticeText $NoPasswordNoticeBox -PasswordBox $NewUserPasswordBox -ConfirmPasswordBox $NewUserConfirmPasswordBox
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Password choice error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $NoPasswordOption.Add_MouseLeftButtonUp({
    try {
      Set-GuiCreateUserPasswordChoice -NoPassword $true -SetOption $SetPasswordOption -SetOptionText $SetPasswordOptionText -NoPasswordOption $NoPasswordOption -NoPasswordOptionText $NoPasswordOptionText -PasswordFieldsPanel $NewUserPasswordFieldsPanel -NoticeText $NoPasswordNoticeBox -PasswordBox $NewUserPasswordBox -ConfirmPasswordBox $NewUserConfirmPasswordBox
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Password choice error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $CreateUserButton.Add_Click({
    try {
      Invoke-GuiLocalUserCreation -UserNameTextBox $NewUserNameTextBox -FullNameTextBox $NewUserFullNameTextBox -PasswordBox $NewUserPasswordBox -ConfirmPasswordBox $NewUserConfirmPasswordBox -ListPanel $LocalUsersListPanel -NoPassword $script:GuiCreateUserNoPassword
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Create user error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $ApplyPowerSettingsButton.Add_Click({
    try {
      Invoke-GuiPowerSettingsApply -PluggedInMinutesTextBox $PluggedInMinutesTextBox -BatteryMinutesTextBox $BatteryMinutesTextBox -CurrentPluggedInText $CurrentPluggedInText -CurrentBatteryText $CurrentBatteryText
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Apply power settings error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $SaveAssetIdButton.Add_Click({
    try {
      Invoke-GuiAssetIdSave -FieldTextBoxes $AssetIdFieldTextBoxes
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Save asset ID error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $NavApplications = $Window.FindName("NavApplications")
  $NavApplicationsText = $Window.FindName("NavApplicationsText")
  $NavApplicationsIcon = $Window.FindName("NavApplicationsIcon")
  $NavWindowsSetup = $Window.FindName("NavWindowsSetup")
  $NavWindowsSetupText = $Window.FindName("NavWindowsSetupText")
  $NavWindowsSetupIcon = $Window.FindName("NavWindowsSetupIcon")
  $NavDeviceDetails = $Window.FindName("NavDeviceDetails")
  $NavDeviceDetailsText = $Window.FindName("NavDeviceDetailsText")
  $NavDeviceDetailsIcon = $Window.FindName("NavDeviceDetailsIcon")
  $NavDeploymentLogs = $Window.FindName("NavDeploymentLogs")
  $NavDeploymentLogsText = $Window.FindName("NavDeploymentLogsText")
  $NavDeploymentLogsIcon = $Window.FindName("NavDeploymentLogsIcon")
  $NavDeploymentValidation = $Window.FindName("NavDeploymentValidation")
  $NavDeploymentValidationText = $Window.FindName("NavDeploymentValidationText")
  $NavDeploymentValidationIcon = $Window.FindName("NavDeploymentValidationIcon")
  $NavTempCleanup = $Window.FindName("NavTempCleanup")
  $NavTempCleanupText = $Window.FindName("NavTempCleanupText")
  $NavTempCleanupIcon = $Window.FindName("NavTempCleanupIcon")

  $script:GuiQueueRunning = $false
  $script:GuiSelectedCountText = $SelectedCountText
  $script:GuiDeploymentValidationLoaded = $false
  $script:GuiDeploymentLogsLoaded = $false
  $script:GuiWindowsConfigLoaded = $false
  $script:GuiTempCleanupLoaded = $false
  $script:GuiNavBorders = @($NavApplications, $NavWindowsSetup, $NavDeviceDetails, $NavAssetId, $NavDeploymentLogs, $NavDeploymentValidation, $NavTempCleanup)
  $script:GuiNavTexts = @($NavApplicationsText, $NavWindowsSetupText, $NavDeviceDetailsText, $NavAssetIdText, $NavDeploymentLogsText, $NavDeploymentValidationText, $NavTempCleanupText)
  $script:GuiNavIcons = @($NavApplicationsIcon, $NavWindowsSetupIcon, $NavDeviceDetailsIcon, $NavAssetIdIcon, $NavDeploymentLogsIcon, $NavDeploymentValidationIcon, $NavTempCleanupIcon)
  $script:GuiApplicationsToolbar = $Window.FindName("ApplicationsToolbar")
  $script:GuiApplicationsScrollViewer = $Window.FindName("ApplicationsScrollViewer")
  $script:GuiPlaceholderText = $Window.FindName("PlaceholderText")
  $script:GuiDeploymentValidationToolbar = $Window.FindName("DeploymentValidationToolbar")
  $script:GuiDeploymentValidationScrollViewer = $Window.FindName("DeploymentValidationScrollViewer")
  $script:GuiDeploymentValidationPanel = $DeploymentValidationPanel
  $script:GuiValidationSummaryText = $ValidationSummaryText
  $script:GuiRerunValidationButton = $RerunValidationButton
  $script:GuiRefreshWindowsConfigButtons = @($RefreshWindowsSetupButton, $RefreshDeviceDetailsButton, $RefreshAssetIdButton)
  $script:GuiDeploymentLogsToolbar = $Window.FindName("DeploymentLogsToolbar")
  $script:GuiDeploymentLogsContent = $Window.FindName("DeploymentLogsContent")
  $script:GuiDeploymentLogsPanel = $DeploymentLogsPanel
  $script:GuiLogContentTextBox = $LogContentTextBox
  $script:GuiSelectedLogNameText = $SelectedLogNameText
  $script:GuiWindowsSetupToolbar = $Window.FindName("WindowsSetupToolbar")
  $script:GuiWindowsSetupScrollViewer = $Window.FindName("WindowsSetupScrollViewer")
  $script:GuiDeviceDetailsToolbar = $Window.FindName("DeviceDetailsToolbar")
  $script:GuiDeviceDetailsScrollViewer = $Window.FindName("DeviceDetailsScrollViewer")
  $script:GuiWindowsConfigDeviceFields = $WindowsConfigDeviceFields
  $script:GuiCurrentComputerNameText = $CurrentComputerNameText
  $script:GuiLocalUsersListPanel = $LocalUsersListPanel
  $script:GuiCurrentPluggedInText = $CurrentPluggedInText
  $script:GuiCurrentBatteryText = $CurrentBatteryText
  $script:GuiNavAssetId = $NavAssetId
  $script:GuiAssetIdToolbar = $AssetIdToolbar
  $script:GuiAssetIdScrollViewer = $AssetIdScrollViewer
  $script:GuiAssetIdFieldTextBoxes = $AssetIdFieldTextBoxes
  $script:GuiTempCleanupToolbar = $TempCleanupToolbar
  $script:GuiTempCleanupScrollViewer = $TempCleanupScrollViewer
  $script:GuiTempCleanupCardControls = $TempCleanupCardControls
  $script:GuiRefreshTempCleanupButton = $RefreshTempCleanupButton
  $script:GuiCleanSelectedTempButton = $CleanSelectedTempButton

  $NavApplications.Add_MouseLeftButtonUp({
    try {
      Switch-GuiScreen -ScreenName "Applications" -ActiveBorder $NavApplications -ActiveText $NavApplicationsText -ActiveIcon $NavApplicationsIcon
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Navigation error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $NavWindowsSetup.Add_MouseLeftButtonUp({
    try {
      Switch-GuiScreen -ScreenName "Windows Setup" -ActiveBorder $NavWindowsSetup -ActiveText $NavWindowsSetupText -ActiveIcon $NavWindowsSetupIcon
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Navigation error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $NavDeviceDetails.Add_MouseLeftButtonUp({
    try {
      Switch-GuiScreen -ScreenName "Device Details" -ActiveBorder $NavDeviceDetails -ActiveText $NavDeviceDetailsText -ActiveIcon $NavDeviceDetailsIcon
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Navigation error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $NavAssetId.Add_MouseLeftButtonUp({
    try {
      Switch-GuiScreen -ScreenName "Asset ID" -ActiveBorder $NavAssetId -ActiveText $NavAssetIdText -ActiveIcon $NavAssetIdIcon
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Navigation error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $NavDeploymentLogs.Add_MouseLeftButtonUp({
    try {
      Switch-GuiScreen -ScreenName "Deployment Logs" -ActiveBorder $NavDeploymentLogs -ActiveText $NavDeploymentLogsText -ActiveIcon $NavDeploymentLogsIcon
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Navigation error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $NavDeploymentValidation.Add_MouseLeftButtonUp({
    try {
      Switch-GuiScreen -ScreenName "Deployment Validation" -ActiveBorder $NavDeploymentValidation -ActiveText $NavDeploymentValidationText -ActiveIcon $NavDeploymentValidationIcon
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Navigation error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
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
