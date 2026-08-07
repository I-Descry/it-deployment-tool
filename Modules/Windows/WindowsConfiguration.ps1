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

function Show-WindowsConfigurationReport {
  Clear-Host

  Write-Title -Title "CURRENT WINDOWS CONFIGURATION"

  $ComputerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
  $OperatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
  $BiosInformation = Get-CimInstance -ClassName Win32_BIOS -ErrorAction SilentlyContinue
  $PowerConfiguration = Get-CurrentPowerConfiguration
  $CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $CurrentUser = $CurrentIdentity.Name

  if (($null -ne $ComputerSystem) -and (-not [string]::IsNullOrWhiteSpace([string]$ComputerSystem.UserName))) {
    $CurrentUser = $ComputerSystem.UserName
  }

  Write-Section -Title "Computer Information"

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
  Write-Info -Name "Computer Name" -Value $ComputerName
  Write-Info -Name "Manufacturer" -Value ([string]$ComputerSystem.Manufacturer)
  Write-Info -Name "Model" -Value ([string]$ComputerSystem.Model)
  Write-Info -Name "Serial Number" -Value ([string]$BiosInformation.SerialNumber)

  $NetworkType = "Workgroup"

  if ([bool]$ComputerSystem.PartOfDomain) {
    $NetworkType = "Domain"
  }

  Write-Info -Name "Network Type" -Value $NetworkType
  Write-Info -Name "Domain/Workgroup" -Value ([string]$ComputerSystem.Domain)
  Write-Section -Title "Windows Information"
  Write-Info -Name "Edition" -Value ([string]$OperatingSystem.Caption)
  Write-Info -Name "Version" -Value ([string]$OperatingSystem.Version)
  Write-Info -Name "Build Number" -Value ([string]$OperatingSystem.BuildNumber)
  Write-Info -Name "Architecture" -Value ([string]$OperatingSystem.OSArchitecture)
  Write-Section -Title "Account Information"
  Write-Info -Name "Logged User" -Value $CurrentUser
  Write-Status -Name "Administrator" -Status (Test-CurrentProcessAdministrator)
  Write-Section -Title "Power Configuration"
  Write-Info -Name "Active Plan" -Value ([string]$PowerConfiguration.ActivePlan)
  Write-Info -Name "Sleep - Plugged" -Value ([string]$PowerConfiguration.SleepAC)
  Write-Info -Name "Sleep - Battery" -Value ([string]$PowerConfiguration.SleepDC)
}