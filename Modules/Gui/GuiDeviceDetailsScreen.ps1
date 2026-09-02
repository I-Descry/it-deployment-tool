# ============================================================
# GUI DEVICE DETAILS SCREEN
# ============================================================
# The read-only device report tab: a plain-text clipboard summary of the same fields Update-GuiWindowsConfigDeviceInfo (GuiWindowsConfigShared.ps1) already populates into the Device Details cards.

function Get-GuiDeviceDetailsSummary {
  param(
    [Parameter(Mandatory)]
    [hashtable]$DeviceFields
  )

  $Lines = @(
    "Computer Name     : {0}" -f $DeviceFields.ComputerName.Text
    "Manufacturer      : {0}" -f $DeviceFields.Manufacturer.Text
    "Model             : {0}" -f $DeviceFields.Model.Text
    "Serial Number     : {0}" -f $DeviceFields.SerialNumber.Text
    "BIOS Version      : {0}" -f $DeviceFields.BiosVersion.Text
    "Asset Tag         : {0}" -f $DeviceFields.AssetTag.Text
    "Network Type      : {0}" -f $DeviceFields.NetworkType.Text
    "IP Address        : {0}" -f $DeviceFields.IPAddress.Text
    "MAC Address       : {0}" -f $DeviceFields.MacAddress.Text
    "Domain/Workgroup  : {0}" -f $DeviceFields.DomainWorkgroup.Text
    "OS Edition        : {0}" -f $DeviceFields.OSEdition.Text
    "OS Version        : {0}" -f $DeviceFields.OSVersion.Text
    "Build Number      : {0}" -f $DeviceFields.OSBuildNumber.Text
    "Architecture      : {0}" -f $DeviceFields.OSArchitecture.Text
    "Activation        : {0}" -f $DeviceFields.ActivationStatus.Text
    "Last Update       : {0}" -f $DeviceFields.LastUpdateInstalled.Text
    "Uptime            : {0}" -f $DeviceFields.Uptime.Text
    "Logged User       : {0}" -f $DeviceFields.LoggedUser.Text
    "Administrator     : {0}" -f $DeviceFields.AdminStatus.Text
    "Active Power Plan : {0}" -f $DeviceFields.PowerPlan.Text
    "Sleep Settings    : {0}" -f $DeviceFields.Sleep.Text
    "Processor         : {0}" -f $DeviceFields.Processor.Text
    "Memory            : {0}" -f $DeviceFields.Memory.Text
    "Storage           : {0}" -f $DeviceFields.Storage.Text
    "TPM               : {0}" -f $DeviceFields.TpmStatus.Text
    "Secure Boot       : {0}" -f $DeviceFields.SecureBootStatus.Text
    "Battery Health    : {0}" -f $DeviceFields.BatteryHealth.Text
    "Antivirus         : {0}" -f $DeviceFields.AntivirusStatus.Text
    "Firewall          : {0}" -f $DeviceFields.FirewallStatus.Text
  )

  return ($Lines -join [Environment]::NewLine)
}

function Invoke-GuiCopyDeviceDetails {
  param(
    [Parameter(Mandatory)]
    [hashtable]$DeviceFields,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Button]$CopyButton
  )

  $SummaryText = Get-GuiDeviceDetailsSummary -DeviceFields $DeviceFields

  try {
    [System.Windows.Clipboard]::SetText($SummaryText)
  }
  catch {
    Show-GuiDialog -Title "Error" -Icon Warning -Message "Could not copy device details to the clipboard: $($_.Exception.Message)"
    return
  }

  $script:GuiCopyDeviceDetailsButton = $CopyButton
  $script:GuiCopyDeviceDetailsOriginalContent = $CopyButton.Content

  $CopyButton.Content = "Copied!"
  $CopyButton.IsEnabled = $false

  $Timer = New-Object System.Windows.Threading.DispatcherTimer
  $Timer.Interval = [TimeSpan]::FromMilliseconds(1400)
  $script:GuiCopyDeviceDetailsResetTimer = $Timer

  # Plain scriptblock -- deliberately NOT .GetNewClosure()'d, matching every other background-runspace/UI timer handler in this app.
  $Timer.Add_Tick({
    $script:GuiCopyDeviceDetailsResetTimer.Stop()
    $script:GuiCopyDeviceDetailsButton.Content = $script:GuiCopyDeviceDetailsOriginalContent
    $script:GuiCopyDeviceDetailsButton.IsEnabled = $true
  })

  $Timer.Start()
}

function Initialize-GuiDeviceDetailsScreen {
  # FindName + click-handler wiring for this screen, called once from Show-MainWindow (GuiWindow.ps1). Windows Setup, Device Details, and Asset ID share one Refresh mechanism (Invoke-GuiWindowsConfigurationRefresh, GuiWindowsConfigShared.ps1), so the orchestrator wires all three screens' Refresh buttons itself once it has collected every screen's own controls -- this function only returns the pieces of itself that refresh needs (DeviceFields/RefreshButton), alongside the Nav Border/Text/Icon triple for the shared nav arrays.
  param(
    [Parameter(Mandatory)]
    [System.Windows.Window]$Window
  )

  $RefreshDeviceDetailsButton = $Window.FindName("RefreshDeviceDetailsButton")
  $CopyDeviceDetailsButton = $Window.FindName("CopyDeviceDetailsButton")
  $NavDeviceDetails = $Window.FindName("NavDeviceDetails")
  $NavDeviceDetailsText = $Window.FindName("NavDeviceDetailsText")
  $NavDeviceDetailsIcon = $Window.FindName("NavDeviceDetailsIcon")

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

  $script:GuiDeviceDetailsToolbar = $Window.FindName("DeviceDetailsToolbar")
  $script:GuiDeviceDetailsScrollViewer = $Window.FindName("DeviceDetailsScrollViewer")
  $script:GuiWindowsConfigDeviceFields = $WindowsConfigDeviceFields

  $CopyDeviceDetailsButton.Add_Click({
    try {
      Invoke-GuiCopyDeviceDetails -DeviceFields $WindowsConfigDeviceFields -CopyButton $CopyDeviceDetailsButton
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Copy device details error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
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

  return @{
    NavBorder     = $NavDeviceDetails
    NavText       = $NavDeviceDetailsText
    NavIcon       = $NavDeviceDetailsIcon
    RefreshButton = $RefreshDeviceDetailsButton
    DeviceFields  = $WindowsConfigDeviceFields
  }
}
