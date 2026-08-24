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

  $script:WindowsConfigurationIdentityCache = [PSCustomObject]@{
    ComputerName    = $ComputerName
    Manufacturer    = [string]$ComputerSystem.Manufacturer
    Model           = [string]$ComputerSystem.Model
    SerialNumber    = [string]$BiosInformation.SerialNumber
    NetworkType     = $NetworkType
    DomainWorkgroup = [string]$ComputerSystem.Domain
    OSEdition       = [string]$OperatingSystem.Caption
    OSVersion       = [string]$OperatingSystem.Version
    OSBuildNumber   = [string]$OperatingSystem.BuildNumber
    OSArchitecture  = [string]$OperatingSystem.OSArchitecture
    IsAdministrator = [bool](Test-CurrentProcessAdministrator)
    ComputerSystemUserName = [string]$ComputerSystem.UserName
  }

  return $script:WindowsConfigurationIdentityCache
}

function Get-WindowsConfigurationReport {
  [CmdletBinding()]
  param()

  $Identity = Get-WindowsConfigurationIdentity
  $PowerConfiguration = Get-CurrentPowerConfiguration

  $CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent().Name

  if (-not [string]::IsNullOrWhiteSpace($Identity.ComputerSystemUserName)) {
    $CurrentUser = $Identity.ComputerSystemUserName
  }

  return [PSCustomObject]@{
    ComputerName    = $Identity.ComputerName
    Manufacturer    = $Identity.Manufacturer
    Model           = $Identity.Model
    SerialNumber    = $Identity.SerialNumber
    NetworkType     = $Identity.NetworkType
    DomainWorkgroup = $Identity.DomainWorkgroup
    OSEdition       = $Identity.OSEdition
    OSVersion       = $Identity.OSVersion
    OSBuildNumber   = $Identity.OSBuildNumber
    OSArchitecture  = $Identity.OSArchitecture
    LoggedUser      = $CurrentUser
    IsAdministrator = $Identity.IsAdministrator
    ActivePowerPlan = [string]$PowerConfiguration.ActivePlan
    SleepAC         = [string]$PowerConfiguration.SleepAC
    SleepDC         = [string]$PowerConfiguration.SleepDC
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
  Write-Info -Name "Network Type" -Value $Report.NetworkType
  Write-Info -Name "Domain/Workgroup" -Value $Report.DomainWorkgroup
  Write-Section -Title "Windows Information"
  Write-Info -Name "Edition" -Value $Report.OSEdition
  Write-Info -Name "Version" -Value $Report.OSVersion
  Write-Info -Name "Build Number" -Value $Report.OSBuildNumber
  Write-Info -Name "Architecture" -Value $Report.OSArchitecture
  Write-Section -Title "Account Information"
  Write-Info -Name "Logged User" -Value $Report.LoggedUser
  Write-Status -Name "Administrator" -Status $Report.IsAdministrator
  Write-Section -Title "Power Configuration"
  Write-Info -Name "Active Plan" -Value $Report.ActivePowerPlan
  Write-Info -Name "Sleep - Plugged" -Value $Report.SleepAC
  Write-Info -Name "Sleep - Battery" -Value $Report.SleepDC
}