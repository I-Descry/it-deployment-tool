# ============================================================
# DEPLOYMENT VALIDATION
# ============================================================

function New-DeploymentValidationResult {
  param(
    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter(Mandatory)]
    [bool]$Passed,

    [Parameter(Mandatory)]
    [string]$Detail
  )

  return [PSCustomObject]@{
    Name   = $Name
    Passed = $Passed
    Detail = $Detail
  }
}

function Convert-ValidationTimeoutToText {
  param(
    [AllowNull()]
    [object]$Minutes
  )

  if ($null -eq $Minutes) {
    return "Unknown"
  }

  $TimeoutMinutes = [int]$Minutes

  if ($TimeoutMinutes -eq 0) {
    return "Never"
  }

  if ($TimeoutMinutes -eq 1) {
    return "1 minute"
  }

  return "$TimeoutMinutes minutes"
}

function Test-DeploymentPendingRestart {
  $RestartRequired = $false

  $RestartRegistryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
  )

  foreach ($RegistryPath in $RestartRegistryPaths) {
    if (Test-Path -LiteralPath $RegistryPath) {
      $RestartRequired = $true
      break
    }
  }

  if (-not $RestartRequired) {
    $SessionManager = Get-ItemProperty -LiteralPath "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name "PendingFileRenameOperations" -ErrorAction SilentlyContinue

    if ($null -ne $SessionManager) {
      $PendingOperations = @($SessionManager.PendingFileRenameOperations)

      if ($PendingOperations.Count -gt 0) {
        $RestartRequired = $true
      }
    }
  }

  return $RestartRequired
}

function Get-ComputerNameValidationResult {
  $ComputerName = [string]$env:COMPUTERNAME

  $UsesDefaultName = ([string]::IsNullOrWhiteSpace($ComputerName) -or $ComputerName -match "^(DESKTOP|LAPTOP|WIN)-")

  if ($UsesDefaultName) {
    return New-DeploymentValidationResult -Name "Computer Name" -Passed $false -Detail "$ComputerName appears to be a default Windows name."
  }

  return New-DeploymentValidationResult -Name "Computer Name" -Passed $true -Detail $ComputerName
}

function Get-PowerConfigurationValidationResult {
  $PowerCommand = Get-Command -Name "Get-CurrentSleepTimeoutMinutes" -ErrorAction SilentlyContinue

  if ($null -eq $PowerCommand) {
    return New-DeploymentValidationResult -Name "Power Settings" -Passed $false -Detail "Power configuration module is unavailable."
  }

  $Timeouts = Get-CurrentSleepTimeoutMinutes
  $PluggedInText = Convert-ValidationTimeoutToText -Minutes $Timeouts.PluggedInMinutes
  $BatteryText = Convert-ValidationTimeoutToText -Minutes $Timeouts.BatteryMinutes

  $SettingsReadable = (($null -ne $Timeouts.PluggedInMinutes) -and ($null -ne $Timeouts.BatteryMinutes))

  return New-DeploymentValidationResult -Name "Power Settings" -Passed $SettingsReadable -Detail ("Plugged in: {0}; Battery: {1}" -f $PluggedInText, $BatteryText)
}

function Get-CrowdStrikeValidationResult {
  $DetectionCommand = Get-Command -Name "Test-CrowdStrikeSensorInstalled" -ErrorAction SilentlyContinue

  if ($null -eq $DetectionCommand) {
    return New-DeploymentValidationResult -Name "CrowdStrike" -Passed $false -Detail "CrowdStrike detection is unavailable."
  }

  $Installed = [bool](Test-CrowdStrikeSensorInstalled)

  if ($Installed) {
    return New-DeploymentValidationResult -Name "CrowdStrike" -Passed $true -Detail "Falcon sensor service detected."
  }

  return New-DeploymentValidationResult -Name "CrowdStrike" -Passed $false -Detail "Falcon sensor service was not detected."
}

function Get-OfficeValidationResult {
  $Office2024Installed = $false
  $Office2021Installed = $false

  $Office2024Command = Get-Command -Name "Test-Office2024Installed" -ErrorAction SilentlyContinue

  if ($null -ne $Office2024Command) {
    $Office2024Installed = [bool](Test-Office2024Installed)
  }

  $Office2021Command = Get-Command -Name "Test-Office2021ProPlusRetailInstalled" -ErrorAction SilentlyContinue

  if ($null -ne $Office2021Command) {
    $Office2021Installed = [bool](Test-Office2021ProPlusRetailInstalled)
  }

  if ($Office2024Installed -and $Office2021Installed) {
    return New-DeploymentValidationResult -Name "Microsoft Office" -Passed $false -Detail "Conflicting Office 2024 and Office 2021 products detected."
  }

  if ($Office2024Installed) {
    return New-DeploymentValidationResult -Name "Microsoft Office" -Passed $true -Detail "Office LTSC Standard 2024 detected."
  }

  if ($Office2021Installed) {
    return New-DeploymentValidationResult -Name "Microsoft Office" -Passed $true -Detail "Office Professional Plus 2021 Retail detected."
  }

  return New-DeploymentValidationResult -Name "Microsoft Office" -Passed $false -Detail "Supported Office installation was not detected."
}

function Get-RequiredApplicationsValidationResult {
  $ExcludedInstallTypes = @("CROWDSTRIKE", "OFFICEISO", "OFFICE2021IMG")

  try {
    $RequiredApplications = @(Get-RequiredApplications | Where-Object {
      $InstallType = ([string]$_.InstallType).Trim().ToUpper()

      $ExcludedInstallTypes -notcontains $InstallType
    })
  }

  catch {
    return New-DeploymentValidationResult -Name "Required Applications" -Passed $false -Detail ("Required application validation could not load the " + "application catalog. $($_.Exception.Message)")
  }

  if ($RequiredApplication.Count -eq 0) {
    return New-DeploymentValidationResult -Name "Required Applications" -Passed $true -Detail "No additional required applications are configured."
  }

  $MissingApplications = New-Object "System.Collections.Generic.List[string]"

  foreach ($Application in $RequiredApplications) {
    try {
      $Installed = [bool](Test-ApplicationInstalled -Application $Application)
    }

    catch {
      $Installed = $false
    }

    if (-not $Installed) {
      [void]$MissingApplications.Add([string]$Application.Name)
    }
  }

  if ($MissingApplications.Count -eq 0) {
    $Detail = ("All {0} required application(s) are installed." -f $RequiredApplications.Count)

    return New-DeploymentValidationResult -Name "Required Applications" -Passed $true -Detail $Detail
  }

  $MissingList = ($MissingApplications.ToArray() -join ", ")

  return New-DeploymentValidationResult -Name "Required Applications" -Passed $false -Detail ("Missing: {0}." -f $MissingList)
}

function Get-LocalStandardUserValidationResult {
  $DetectionCommand = Get-Command -Name "Get-DeploymentLocalStandardUsers" -ErrorAction SilentlyContinue

  if ($null -eq $DetectionCommand) {
    return New-DeploymentValidationResult -Name "Local Standard User" -Passed $false -Detail "Local standard user validation is unavailable."
  }

  try {
    $DeploymentUsers = @(Get-DeploymentLocalStandardUsers)
  }

  catch {
    return New-DeploymentValidationResult -Name "Local Standard User" -Passed $false -Detail "Local standard user validation could not be completed."
  }

  if ($DeploymentUsers.Count -eq 0) {
    return New-DeploymentValidationResult -Name "Local Standard User" -Passed $false -Detail "No deployment standard user was detected."
  }

  $UserLabels = @($DeploymentUsers | ForEach-Object {
    if ([string]::IsNullOrWhiteSpace([string]$_.FullName)) {
      [string]$_.Name
    }
    else {
      "{0} ({1})" -f $_.Name, $_.FullName
    }
  })

  $UserList = $UserLabels -join ", "

  if ($DeploymentUsers.Count -eq 1) {
    $Detail = ("Deployment standard user detected: {0}." -f $UserList)
  }
  else {
    $Detail = ("Deployment standard users detected: {0}." -f $UserList)
  }

  return New-DeploymentValidationResult -Name "Local Standard User" -Passed $true -Detail $Detail
}

function Get-DeploymentValidationResults {
  $Results = New-Object "System.Collections.Generic.List[object]"

  # Administrator Check
  $AdministratorStatus = [bool](Test-Administrator -PassThru)

  if ($AdministratorStatus) {
    $AdministratorDetail = "Deployment tool is running elevated."
  }
  else {
    $AdministratorDetail = "Administrator access is required."
  }

  $AdministratorResult = New-DeploymentValidationResult -Name "Administrator" -Passed $AdministratorStatus -Detail $AdministratorDetail

  [void]$Results.Add($AdministratorResult)

  # Internet Check
  $InternetStatus = [bool](Test-Internet -PassThru)

  if ($InternetStatus) {
    $InternetDetail = "Internet connectivity detected."
  }
  else {
    $InternetDetail = "Internet connectivity was not detected."
  }

  $InternetResult = New-DeploymentValidationResult -Name "Internet" -Passed $InternetStatus -Detail $InternetDetail

  [void]$Results.Add($InternetResult)

  # Winget Check
  $WingetStatus = [bool](Test-Winget -PassThru)

  if ($WingetStatus) {
    $WingetDetail = "Winget is available."
  }
  else {
    $WingetDetail = "Winget is unavailable."
  }

  $WingetResult = New-DeploymentValidationResult -Name "Winget" -Passed $WingetStatus -Detail $WingetDetail

  [void]$Results.Add($WingetResult)

  # Computer Name Check
  $ComputerNameResult = Get-ComputerNameValidationResult

  [void]$Results.Add($ComputerNameResult)

  # Local Standard User Check
  $LocalUserResult = Get-LocalStandardUserValidationResult

  [void]$Results.Add($LocalUserResult)

  # Required Applications Check
  $RequiredApplicationsResult = Get-RequiredApplicationsValidationResult

  [void]$Results.Add($RequiredApplicationsResult)

  # Power Configuration Check
  $PowerResult = Get-PowerConfigurationValidationResult

  [void]$Results.Add($PowerResult)

  # CrowdStrike Check
  $CrowdStrikeResult = Get-CrowdStrikeValidationResult

  [void]$Results.Add($CrowdStrikeResult)

  # Microsoft Office Check
  $OfficeResult = Get-OfficeValidationResult

  [void]$Results.Add($OfficeResult)

  # Pending Restart Check
  $RestartRequired = Test-DeploymentPendingRestart

  if ($RestartRequired) {
    $RestartDetail = "Windows requires a restart."
  }
  else {
    $RestartDetail = "No pending restart was detected."
  }

  $RestartResult = New-DeploymentValidationResult -Name "Pending Restart" -Passed (-not $RestartRequired) -Detail $RestartDetail

  [void]$Results.Add($RestartResult)

  return $Results.ToArray()
}

function Write-DeploymentValidationResultsToLog {
  param(
    [Parameter(Mandatory)]
    [object[]]$Results
  )

  $LoggingCommand = Get-Command -Name "Write-DeploymentLog" -ErrorAction SilentlyContinue

  if ($null -eq $LoggingCommand) {
    return
  }

  Write-DeploymentLog -Message "Deployment validation started." -Level "INFO"

  foreach ($Result in $Results) {
    if ($Result.Passed) {
      $ResultStatus = "Passed"
      $LogLevel = "SUCCESS"
    }
    else {
      $ResultStatus = "Failed"
      $LogLevel = "WARNING"
    }

    $LogMessage = ("Validation | {0} | {1} | {2}" -f $Result.Name, $ResultStatus, $Result.Detail)

    Write-DeploymentLog -Message $LogMessage -Level $LogLevel
  }

  $PassedCount = @($Results | Where-Object {
    $_.Passed
  }).Count

  $FailedCount = $Results.Count - $PassedCount

  if ($FailedCount -eq 0) {
    $SummaryLevel = "SUCCESS"
  }
  else {
    $SummaryLevel = "WARNING"
  }

  Write-DeploymentLog -Message ("Validation Summary | Passed: {0} | Failed: {1} | Total: {2}" -f $PassedCount, $FailedCount, $Results.Count) -Level $SummaryLevel
}

function Show-DeploymentValidationReport {
  [CmdletBinding()]
  param(
    [switch]$PassThru
  )

  Clear-Host

  Write-Title -Title "DEPLOYMENT VALIDATION"

  Write-Section -Title "Device Readiness Checks"

  $Results = @(Get-DeploymentValidationResults)

  Write-DeploymentValidationResultsToLog -Results $Results

  foreach ($Result in $Results) {
    Write-Host ("{0,-20}: " -f $Result.Name) -NoNewLine

    if ($Result.Passed) {
      Write-Host "[ OK ]" -ForegroundColor Green
    }
    else {
      Write-Host "[ FAIL ]" -ForegroundColor Red
    }

    Write-Host ("  {0}" -f $Result.Detail) -ForegroundColor DarkGray
  }

  $PassedCount = @($Results | Where-Object {
    $_.Passed
  }).Count

  $FailedCount = $Results.Count - $PassedCount

  Write-Section -Title "Validation Summary"

  Write-Info -Name "Passed" -Value ([string]$PassedCount)
  Write-Info -Name "Failed" -Value ([string]$FailedCount)
  Write-Info -Name "Total Checks" -Value ([string]$Results.Count)

  Write-Host

  if ($FailedCount -eq 0) {
    Write-Host "Device passed all deployment validation checks." -ForegroundColor Green
  }
  else {
    Write-Host "Device requires attention before issuance." -ForegroundColor Yellow
  }

  if ($PassThru) {
    return $Results
  }
}