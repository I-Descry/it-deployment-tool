# ============================================================
# WINDOWS CONFIGURATION
# ============================================================

function Convert-PowerTimeoutToText {
  param(
    [AllowNull()]
    [object]$Seconds
  )

  if ($null -eq $Seconds) {
    return "Unknown"
  }

  $TimeoutSeconds = [int64]$Seconds

  if ($TimeoutSeconds -eq 0) {
    return "Never"
  }

  if (($TimeoutSeconds % 3600) -eq 0) {
    $Hours = $TimeoutSeconds / 3600

    if ($Hours -eq 1) {
      return "1 hour"
    }

    return "$Hours hours"
  }

  if (($TimeoutSeconds % 60) -eq 0) {
    $Minutes = $TimeoutSeconds / 60

    if ($Minutes -eq 1) {
      return "1 minute"
    }

    return "$Minutes minutes"
  }

  return "$TimeoutSeconds seconds"
}

function Get-CurrentPowerConfiguration {
  $PowerConfiguration = [ordered]@{
    ActivePlan = "Unknown"
    SleepAC    = "Unknown"
    SleepDC    = "Unknown"
  }

  try {
    $ActiveSchemeOutput = @(
      & powercfg.exe /GETACTIVESCHEME 2>$null
    )

    $ActiveSchemeText = $ActiveSchemeOutput -join " "

    if ($ActiveSchemeText -match "\((?<PlanName>[^)]+)\)") {
      $PowerConfiguration.ActivePlan = $Matches.PlanName.Trim()
    }

    $SleepSubgroup = "238C9FA8-0AAD-41ED-83F4-97BE242C8F20"
    $SleepTimeoutSetting = "29F6C1DB-86DA-48C5-9FDB-F2B67B1F44DA"

    $SleepOutput = @(& powercfg.exe /QUERY SCHEME_CURRENT $SleepSubgroup $SleepTimeoutSetting 2>$null)
    $SleepText = $SleepOutput -join "`n"
    $AcMatch = [regex]::Match($SleepText, "Current AC Power Setting Index:\s*0x(?<Value>[0-9A-Fa-f]+)", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

    if ($AcMatch.Success) {
      $AcSeconds = [Convert]::ToInt64($AcMatch.Groups["Value"].Value,16)
      $PowerConfiguration.SleepAC = Convert-PowerTimeoutToText -Seconds $AcSeconds
    }

    $DcMatch = [regex]::Match($SleepText, "Current DC Power Setting Index:\s*0x(?<Value>[0-9A-Fa-f]+)", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

    if ($DcMatch.Success) {
      $DcSeconds = [Convert]::ToInt64($DcMatch.Groups["Value"].Value,16)
      $PowerConfiguration.SleepDC = Convert-PowerTimeoutToText -Seconds $DcSeconds
    }
  }
  catch {
    # Keep Unknown values when power information cannot be read.
  }

  return [PSCustomObject]$PowerConfiguration
}

function Test-CurrentProcessAdministrator {
  try {
    $CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)

    return [bool]$CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  }

  catch {
    return $false
  }
}

$script:WindowsConfigurationIdentityCache = $null

function Get-WindowsConfigurationIdentity {
  # Manufacturer, model, serial number, OS edition/version/build/architecture,
  # computer name, network type, and domain/workgroup cannot change while this
  # tool is running, so the underlying CIM/BIOS queries only need to run once
  # per session rather than on every Windows Configuration screen refresh.
  if ($null -ne $script:WindowsConfigurationIdentityCache) {
    return $script:WindowsConfigurationIdentityCache
  }

  $ComputerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
  $OperatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
  $BiosInformation = Get-CimInstance -ClassName Win32_BIOS -ErrorAction SilentlyContinue
  $SystemEnclosure = Get-CimInstance -ClassName Win32_SystemEnclosure -ErrorAction SilentlyContinue

  $ComputerName = [string]([System.Environment]::MachineName)

  if ([string]::IsNullOrWhiteSpace($ComputerName) -and ($null -ne $ComputerSystem)) {
    $ComputerName = [string]$ComputerSystem.Name
  }

  if ([string]::IsNullOrWhiteSpace($ComputerName)) {
    $HostNameOutput = @(& hostname.exe 2>$null)
    $ComputerName = ($HostNameOutput -join "").Trim()
  }

  if ([string]::IsNullOrWhiteSpace($ComputerName)) {
    $ComputerName = "Unknown"
  }

  $NetworkType = "Workgroup"

  if ([bool]$ComputerSystem.PartOfDomain) {
    $NetworkType = "Domain"
  }

  $Processor = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
  $MemoryModules = @(Get-CimInstance -ClassName Win32_PhysicalMemory -ErrorAction SilentlyContinue)
  $TotalMemoryBytes = ($MemoryModules | Measure-Object -Property Capacity -Sum).Sum

  # TPM lives in its own WMI namespace, separate from the general CIM classes
  # above. It legitimately returns nothing on a VM without a virtual TPM, on a
  # device with no TPM chip, or when access is denied by policy, so this must
  # degrade to "not available" rather than treat a null result as an error.
  $Tpm = Get-CimInstance -Namespace "root\cimv2\Security\MicrosoftTpm" -ClassName Win32_Tpm -ErrorAction SilentlyContinue
  $TpmReady = $false
  $TpmStatus = "Not Available"

  if ($null -ne $Tpm) {
    $TpmReady = [bool]$Tpm.IsActivated_InitialValue -and [bool]$Tpm.IsEnabled_InitialValue
    $TpmSpecVersion = ([string]$Tpm.SpecVersion -split ",")[0].Trim()
    $TpmStatus = if ($TpmReady) { "Ready $TpmSpecVersion" } else { "Not Ready" }
  }

  # Queried once and cached here rather than fresh on every refresh (the
  # mistake this had originally, measured directly against this real
  # machine: Get-PhysicalDisk took ~4.1s *per call*, so re-running it on
  # every Windows Setup/Device Details refresh added real seconds of extra
  # wait every time). Disk media type is exactly as static as
  # Manufacturer/Model/TPM above for the lifetime of this tool's session,
  # so it belongs in this cached block with everything else that "cannot
  # change while this tool is running", not in the per-refresh functions.
  $DiskMediaType = $null

  try {
    $DiskMediaType = (Get-PhysicalDisk -ErrorAction Stop | Select-Object -First 1).MediaType
  }
  catch {
    # Leave $DiskMediaType unset if Get-PhysicalDisk is unavailable.
  }

  # Confirm-SecureBootUEFI hit the same "Access denied" elevation-token issue
  # BitLocker did when that was tried and dropped -- unlike BitLocker, though,
  # it fails fast (~180ms measured), so keeping it here costs nothing
  # meaningful even when it can't answer. Degrades to "Unknown" on any
  # failure (including a non-UEFI/legacy BIOS system, which also throws
  # here) rather than treating it as On/Off.
  $SecureBootStatus = "Unknown"

  try {
    $SecureBootStatus = if (Confirm-SecureBootUEFI -ErrorAction Stop) { "On" } else { "Off" }
  }
  catch {
    # Keep "Unknown" on any failure (access denied, legacy BIOS, etc.)
  }

  # Get-HotFix (Win32_QuickFixEngineering) measured ~3s per call -- real,
  # but cached here once per session rather than queried fresh, the same
  # fix already applied to disk media type above.
  $LastUpdateInstalled = "Unknown"

  try {
    $LatestHotfix = Get-HotFix -ErrorAction Stop | Sort-Object -Property InstalledOn -Descending | Select-Object -First 1

    if ($null -ne $LatestHotfix -and $null -ne $LatestHotfix.InstalledOn) {
      $LastUpdateInstalled = "{0} ({1:yyyy-MM-dd})" -f $LatestHotfix.HotFixID, $LatestHotfix.InstalledOn
    }
  }
  catch {
    # Keep "Unknown" if the hotfix query itself is unavailable.
  }

  # Battery health (design vs. full-charge capacity) is not exposed by any
  # single fast WMI class on this real hardware -- the natural-looking
  # root\wmi BatteryStaticData/BatteryFullChargedCapacity classes returned
  # "Generic failure" here, and Win32_Battery alone has no capacity fields.
  # powercfg's own battery report (the same one Windows' own battery
  # troubleshooting docs point to) does have both figures and measured
  # ~1.3s end to end, so that's the real source used here. Win32_Battery is
  # checked first and is fast (~600ms) specifically to skip the report
  # entirely on a desktop with no battery, rather than spend 1.3s to learn
  # the same "no battery" answer a cheaper check already gives.
  $BatteryHealth = "No Battery"

  $HasBattery = $false

  try {
    $HasBattery = $null -ne (Get-CimInstance -ClassName Win32_Battery -ErrorAction Stop | Select-Object -First 1)
  }
  catch {
    $HasBattery = $false
  }

  if ($HasBattery) {
    $BatteryHealth = "Unknown"
    $BatteryReportPath = Join-Path $env:TEMP "it-deployment-tool-battery-report.xml"

    try {
      Start-Process -FilePath "powercfg.exe" -ArgumentList @("/batteryreport", "/xml", "/output", $BatteryReportPath) -Wait -WindowStyle Hidden -ErrorAction Stop

      if (Test-Path -LiteralPath $BatteryReportPath -PathType Leaf) {
        [xml]$BatteryReportXml = Get-Content -LiteralPath $BatteryReportPath -Raw
        $BatteryNode = $BatteryReportXml.BatteryReport.Batteries.Battery | Select-Object -First 1

        $DesignCapacity = [double]$BatteryNode.DesignCapacity
        $FullChargeCapacity = [double]$BatteryNode.FullChargeCapacity

        if ($DesignCapacity -gt 0) {
          $HealthPercent = [math]::Round(($FullChargeCapacity / $DesignCapacity) * 100, 0)
          $BatteryHealth = "$HealthPercent% of design capacity"
        }
      }
    }
    catch {
      # Keep "Unknown" if the battery report cannot be generated or parsed.
    }
    finally {
      Remove-Item -LiteralPath $BatteryReportPath -Force -ErrorAction SilentlyContinue
    }
  }

  # The Windows-only Software Licensing entry is isolated via its real,
  # documented Application ID (55c92734-d682-4d71-983e-d6ec3f16059f) --
  # without this filter, a device with Office also installed returns a
  # separate Office licensing entry alongside it. LicenseStatus 1 means
  # Licensed; anything else (0 Unlicensed, grace/notification states, etc.)
  # is reported as-is rather than assumed to mean any one specific problem.
  $ActivationStatus = "Unknown"

  try {
    $WindowsLicense = Get-CimInstance -ClassName SoftwareLicensingProduct -Filter "PartialProductKey is not null AND ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f'" -ErrorAction Stop | Select-Object -First 1

    if ($null -ne $WindowsLicense) {
      $ActivationStatus = if ([int]$WindowsLicense.LicenseStatus -eq 1) { "Licensed" } else { "Not Activated" }
    }
  }
  catch {
    # Keep "Unknown" if the licensing query itself is unavailable.
  }

  $script:WindowsConfigurationIdentityCache = [PSCustomObject]@{
    ComputerName    = $ComputerName
    Manufacturer    = [string]$ComputerSystem.Manufacturer
    Model           = [string]$ComputerSystem.Model
    SerialNumber    = [string]$BiosInformation.SerialNumber
    BiosVersion     = if ([string]::IsNullOrWhiteSpace([string]$BiosInformation.SMBIOSBIOSVersion)) { "Unknown" } else { [string]$BiosInformation.SMBIOSBIOSVersion }
    # SMBIOSAssetTag is commonly blank until something (like this tool's own
    # Lenovo Asset ID feature) has actually set it -- "Not Set" distinguishes
    # that real, normal state from a query failure ("Unknown" elsewhere here).
    AssetTag        = if ([string]::IsNullOrWhiteSpace([string]$SystemEnclosure.SMBIOSAssetTag)) { "Not Set" } else { [string]$SystemEnclosure.SMBIOSAssetTag }
    ActivationStatus = $ActivationStatus
    NetworkType     = $NetworkType
    DomainWorkgroup = [string]$ComputerSystem.Domain
    OSEdition       = [string]$OperatingSystem.Caption
    OSVersion       = [string]$OperatingSystem.Version
    OSBuildNumber   = [string]$OperatingSystem.BuildNumber
    OSArchitecture  = [string]$OperatingSystem.OSArchitecture
    IsAdministrator = [bool](Test-CurrentProcessAdministrator)
    ComputerSystemUserName = [string]$ComputerSystem.UserName
    Processor       = if ($null -ne $Processor) { ([string]$Processor.Name).Trim() } else { "Unknown" }
    MemoryGB        = if ($TotalMemoryBytes) { "$([math]::Round($TotalMemoryBytes / 1GB, 0)) GB" } else { "Unknown" }
    TpmReady        = $TpmReady
    TpmStatus       = $TpmStatus
    DiskMediaType   = $DiskMediaType
    SecureBootStatus = $SecureBootStatus
    LastUpdateInstalled = $LastUpdateInstalled
    BatteryHealth   = $BatteryHealth
    # Win32_ComputerSystem.Model is a raw machine-type code on Lenovo systems
    # (e.g. "21SR0038PH"), not a usable product name -- SystemFamily is the
    # field that actually holds the human-readable family name (e.g. "ThinkPad
    # E16 Gen 3"), confirmed against this exact CIM query on real Lenovo
    # hardware before relying on it.
    IsThinkPad      = ([string]$ComputerSystem.Manufacturer).Trim() -eq "LENOVO" -and ([string]$ComputerSystem.SystemFamily) -match "ThinkPad"
  }

  return $script:WindowsConfigurationIdentityCache
}

function Get-WindowsConfigurationStorage {
  # Free/total space is queried fresh on every report rather than cached
  # with the rest of the hardware identity, since it changes as this tool
  # installs applications during the same session. Disk media type
  # (SSD/HDD) is passed in from the cached identity instead of being
  # queried here every time -- Get-PhysicalDisk alone measured ~4.1s per
  # call against this real machine, and unlike free space, media type
  # cannot change during a session.
  param(
    [AllowNull()]
    [string]$MediaType
  )

  $SystemDrive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$($env:SystemDrive)'" -ErrorAction SilentlyContinue

  if ($null -eq $SystemDrive -or $null -eq $SystemDrive.Size -or $null -eq $SystemDrive.FreeSpace) {
    return "Unknown"
  }

  $FreeGB = [math]::Round($SystemDrive.FreeSpace / 1GB, 0)
  $TotalGB = [math]::Round($SystemDrive.Size / 1GB, 0)

  if ([string]::IsNullOrWhiteSpace($MediaType) -or $MediaType -eq "Unspecified") {
    return "$FreeGB GB free of $TotalGB GB"
  }

  return "$FreeGB GB free of $TotalGB GB ($MediaType)"
}

function Get-WindowsConfigurationNetwork {
  # Queried fresh on every report, not cached: unlike the static hardware
  # identity above, an IP address can genuinely change during a session
  # (DHCP renewal, switching networks). Only the first IP-enabled adapter is
  # shown, matching how the rest of this screen already shows one summary
  # value per fact rather than enumerating every adapter.
  $Adapter = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter "IPEnabled=TRUE" -ErrorAction SilentlyContinue | Select-Object -First 1

  if ($null -eq $Adapter) {
    return [PSCustomObject]@{
      IPAddress  = "Unknown"
      MacAddress = "Unknown"
    }
  }

  $IPv4Address = @($Adapter.IPAddress) | Where-Object { $_ -notmatch ":" } | Select-Object -First 1

  return [PSCustomObject]@{
    IPAddress  = if ([string]::IsNullOrWhiteSpace([string]$IPv4Address)) { "Unknown" } else { [string]$IPv4Address }
    MacAddress = if ([string]::IsNullOrWhiteSpace([string]$Adapter.MACAddress)) { "Unknown" } else { [string]$Adapter.MACAddress }
  }
}

function Get-WindowsConfigurationReport {
  [CmdletBinding()]
  param()

  $Identity = Get-WindowsConfigurationIdentity
  $PowerConfiguration = Get-CurrentPowerConfiguration
  $Network = Get-WindowsConfigurationNetwork

  $CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent().Name

  if (-not [string]::IsNullOrWhiteSpace($Identity.ComputerSystemUserName)) {
    $CurrentUser = $Identity.ComputerSystemUserName
  }

  return [PSCustomObject]@{
    ComputerName      = $Identity.ComputerName
    Manufacturer      = $Identity.Manufacturer
    Model             = $Identity.Model
    SerialNumber      = $Identity.SerialNumber
    BiosVersion       = $Identity.BiosVersion
    AssetTag          = $Identity.AssetTag
    ActivationStatus  = $Identity.ActivationStatus
    NetworkType       = $Identity.NetworkType
    IPAddress         = $Network.IPAddress
    MacAddress        = $Network.MacAddress
    DomainWorkgroup   = $Identity.DomainWorkgroup
    OSEdition         = $Identity.OSEdition
    OSVersion         = $Identity.OSVersion
    OSBuildNumber     = $Identity.OSBuildNumber
    OSArchitecture    = $Identity.OSArchitecture
    LastUpdateInstalled = $Identity.LastUpdateInstalled
    LoggedUser        = $CurrentUser
    IsAdministrator   = $Identity.IsAdministrator
    ActivePowerPlan   = [string]$PowerConfiguration.ActivePlan
    SleepAC           = [string]$PowerConfiguration.SleepAC
    SleepDC           = [string]$PowerConfiguration.SleepDC
    Processor         = $Identity.Processor
    MemoryGB          = $Identity.MemoryGB
    Storage           = Get-WindowsConfigurationStorage -MediaType $Identity.DiskMediaType
    TpmReady          = $Identity.TpmReady
    TpmStatus         = $Identity.TpmStatus
    SecureBootStatus  = $Identity.SecureBootStatus
    BatteryHealth     = $Identity.BatteryHealth
    IsThinkPad        = $Identity.IsThinkPad
  }
}

function Show-WindowsConfigurationReport {
  Clear-Host

  Write-Title -Title "CURRENT WINDOWS CONFIGURATION"

  $Report = Get-WindowsConfigurationReport

  Write-Section -Title "Computer Information"

  Write-Info -Name "Computer Name" -Value $Report.ComputerName
  Write-Info -Name "Manufacturer" -Value $Report.Manufacturer
  Write-Info -Name "Model" -Value $Report.Model
  Write-Info -Name "Serial Number" -Value $Report.SerialNumber
  Write-Info -Name "BIOS Version" -Value $Report.BiosVersion
  Write-Info -Name "Asset Tag" -Value $Report.AssetTag
  Write-Section -Title "Network"
  Write-Info -Name "Network Type" -Value $Report.NetworkType
  Write-Info -Name "IP Address" -Value $Report.IPAddress
  Write-Info -Name "MAC Address" -Value $Report.MacAddress
  Write-Info -Name "Domain/Workgroup" -Value $Report.DomainWorkgroup
  Write-Section -Title "Windows Information"
  Write-Info -Name "Edition" -Value $Report.OSEdition
  Write-Info -Name "Version" -Value $Report.OSVersion
  Write-Info -Name "Build Number" -Value $Report.OSBuildNumber
  Write-Info -Name "Architecture" -Value $Report.OSArchitecture
  Write-Info -Name "Activation" -Value $Report.ActivationStatus
  Write-Info -Name "Last Update" -Value $Report.LastUpdateInstalled
  Write-Section -Title "Account Information"
  Write-Info -Name "Logged User" -Value $Report.LoggedUser
  Write-Status -Name "Administrator" -Status $Report.IsAdministrator
  Write-Section -Title "Power Configuration"
  Write-Info -Name "Active Plan" -Value $Report.ActivePowerPlan
  Write-Info -Name "Sleep - Plugged" -Value $Report.SleepAC
  Write-Info -Name "Sleep - Battery" -Value $Report.SleepDC
  Write-Section -Title "Hardware"
  Write-Info -Name "Processor" -Value $Report.Processor
  Write-Info -Name "Memory" -Value $Report.MemoryGB
  Write-Info -Name "Storage" -Value $Report.Storage
  Write-Info -Name "TPM" -Value $Report.TpmStatus
  Write-Info -Name "Secure Boot" -Value $Report.SecureBootStatus
  Write-Info -Name "Battery Health" -Value $Report.BatteryHealth
}