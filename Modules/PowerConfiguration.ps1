# ============================================================
# POWER CONFIGURATION
# ============================================================

function Get-CurrentSleepTimeoutMinutes {
  $Timeouts = [ordered]@{
    PluggedInMinutes = $null
    BatteryMinutes   = $null
  }

  try {
    $SleepSubgroup = "238C9FA8-0AAD-41ED-83F4-97BE242C8F20"
    $SleepTimeoutSetting = "29F6C1DB-86DA-48C5-9FDB-F2B67B1F44DA"

    $SleepOutput = @(& powercfg.exe /QUERY SCHEME_CURRENT $SleepSubgroup $SleepTimeoutSetting 2>$null)

    $SleepText = $SleepOutput -join "`n"

    $AcMatch = [regex]::Match($SleepText, "Current AC Power Setting Index:\s*0x(?<Value>[0-9A-Fa-f]+)",[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

    if ($AcMatch.Success) {
      $AcSeconds = [Convert]::ToInt64($AcMatch.Groups["Value"].Value,16)

      $Timeouts.PluggedInMinutes = [int]($AcSeconds / 60)
    }

    $DcMatch = [regex]::Match($SleepText, "Current DC Power Setting Index:\s*0x(?<Value>[0-9A-Fa-f]+)",[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

    if ($DcMatch.Success) {
      $DcSeconds = [Convert]::ToInt64($DcMatch.Groups["Value"].Value,16)

      $Timeouts.BatteryMinutes = [int]($DcSeconds / 60)
    }
  }

  catch {
    # Null values indicate that Windows could not provide the setting.
  }

  return [PSCustomObject]$Timeouts
}

function Test-SleepTimeoutMinutes {
  param(
    [Parameter(Mandatory)]
    [string]$Value,

    [string]$SettingName = "Sleep timeout"
  )

  $ParsedMinutes = 0

  if (-not [int]::TryParse($Value,[ref]$ParsedMinutes)) {
    return [PSCustomObject]@{
      Valid   = $false
      Minutes = $null
      Message = "$SettingName must be a whole number."
    }
  }

  if (($ParsedMinutes -lt 0) -or ($ParsedMinutes -gt 1440)) {
    return [PSCustomObject]@{
      Valid   = $false
      Minutes = $ParsedMinutes
      Message = ("$SettingName must be between 0 and 1440 minutes.")
    }
  }

  return [PSCustomObject]@{
    Valid   = $true
    Minutes = $ParsedMinutes
    Message = "$SettingName is valid."
  }
}

function Convert-SleepTimeoutMinutesToText {
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

function Set-DeploymentSleepTimeouts {
  [CmdletBinding(
    SupportsShouldProcess = $true,
    ConfirmImpact = "High"
  )]
  param(
    [Parameter(Mandatory)]
    [ValidateRange(0, 1440)]
    [int]$PluggedInMinutes,

    [Parameter(Mandatory)]
    [ValidateRange(0, 1440)]
    [int]$BatteryMinutes
  )

  try {
    if ((-not $WhatIfPreference) -and (-not (Test-CurrentProcessAdministrator))) {
      return [PSCustomObject]@{
        Status           = "Failed"
        PluggedInMinutes = $null
        BatteryMinutes   = $null
        Message          = ("Administrator permission is required " + "to change power settings.")
      }
    }

    $CurrentTimeouts = Get-CurrentSleepTimeoutMinutes

    if ((-not $WhatIfPreference) -and ($CurrentTimeouts.PluggedInMinutes -eq $PluggedInMinutes) -and ($CurrentTimeouts.BatteryMinutes -eq $BatteryMinutes)) {
      return [PSCustomObject]@{
        Status           = "Skipped"
        PluggedInMinutes = $CurrentTimeouts.PluggedInMinutes
        BatteryMinutes   = $CurrentTimeouts.BatteryMinutes
        Message          = ("The requested sleep settings are already applied.")
      }
    }

    $ActionDescription = ("Set plugged-in sleep to {0} minutes and " + "battery sleep to {1} minutes" -f $PluggedInMinutes, $BatteryMinutes)

    if (-not $PSCmdlet.ShouldProcess("Active Windows power plan", $ActionDescription)) {
      return [PSCustomObject]@{
        Status           = "Preview Only"
        PluggedInMinutes = $PluggedInMinutes
        BatteryMinutes   = $BatteryMinutes
        Message          = "No power settings were changed."
      }
    }

    $AcOutput = @(& powercfg.exe /CHANGE standby-timeout-ac $PluggedInMinutes 2>&1)
    $AcExitCode = $LASTEXITCODE

    if ($AcExitCode -ne 0) {
      throw ("Windows could not update the plugged-in sleep timeout. " + "Exit code: {0}. Output: {1}" -f $AcExitCode, ($AcOutput -join " "))
    }

    $DcOutput = @(& powercfg.exe /CHANGE standby-timeout-dc $BatteryMinutes 2>&1)
    $DcExitCode = $LASTEXITCODE

    if ($DcExitCode -ne 0) {
      if ($null -ne $CurrentTimeouts.PluggedInMinutes) {
        & powercfg.exe /CHANGE standby-timeout-ac $CurrentTimeouts.PluggedInMinutes 2>$null | Out-Null
      }

      throw ("Windows could not update the battery sleep timeout. " + "Exit code: {0}. Output: {1}" -f $DcExitCode, ($DcOutput -join " "))
    }

    $UpdatedTimeouts = Get-CurrentSleepTimeoutMinutes

    $PluggedInVerified = ($UpdatedTimeouts.PluggedInMinutes -eq $PluggedInMinutes)
    $BatteryVerified = ($UpdatedTimeouts.BatteryMinutes -eq $BatteryMinutes)

    if ((-not $PluggedInVerified) -or (-not $BatteryVerified)) {
      throw ("The power commands completed, but the updated " + "sleep settings could not be verified.")
    }

    return [PSCustomObject]@{
      Status           = "Updated"
      PluggedInMinutes = $UpdatedTimeouts.PluggedInMinutes
      BatteryMinutes   = $UpdatedTimeouts.BatteryMinutes
      Message          = ("Power and sleep settings were updated successfully.")
    }
  }

  catch {
    return [PSCustomObject]@{
      Status           = "Failed"
      PluggedInMinutes = $null
      BatteryMinutes   = $null
      Message          = $_.Exception.Message
    }
  }
}

function Start-PowerConfigurationWizard {
  Clear-Host

  Write-Title -Title "POWER AND SLEEP SETTINGS"

  $CurrentTimeouts = Get-CurrentSleepTimeoutMinutes

  Write-Section -Title "Current Sleep Settings"

  Write-Info -Name "Plugged In" -Value (Convert-SleepTimeoutMinutesToText -Minutes $CurrentTimeouts.PluggedInMinutes)
  Write-Info -Name "On Battery" -Value (Convert-SleepTimeoutMinutesToText -Minutes $CurrentTimeouts.BatteryMinutes)

  Write-Host
  Write-Host "Enter a value from 0 to 1440 minutes." -ForegroundColor DarkGray
  Write-Host "Enter 0 to configure Never sleep." -ForegroundColor DarkGray
  Write-Host "Enter Q at any prompt to cancel." -ForegroundColor DarkGray

  $PluggedInMinutes = $null

  while ($null -eq $PluggedInMinutes) {
    Write-Host

    $PluggedInInput = Read-Host "Sleep timeout when plugged in"

    if ($PluggedInInput.Trim().ToUpper() -eq "Q") {
      Write-Host
      Write-Host "Power configuration cancelled." -ForegroundColor Yellow

      Pause-Application
      return
    }

    $PluggedInTest = Test-SleepTimeoutMinutes -Value $PluggedInInput -SettingName "Plugged-in sleep timeout"

    if (-not $PluggedInTest.Valid) {
      Write-Host $PluggedInTest.Message -ForegroundColor Red

      continue
    }

    $PluggedInMinutes = $PluggedInTest.Minutes
  }

  $BatteryMinutes = $null

  while ($null -eq $BatteryMinutes) {
    Write-Host

    $BatteryInput = Read-Host "Sleep timeout when on battery"

    if ($BatteryInput.Trim().ToUpper() -eq "Q") {
      Write-Host
      Write-Host "Power configuration cancelled." -ForegroundColor Yellow

      Pause-Application
      return
    }

    $BatteryTest = Test-SleepTimeoutMinutes -Value $BatteryInput -SettingName "Battery sleep timeout"

    if (-not $BatteryTest.Valid) {
      Write-Host $BatteryTest.Message -ForegroundColor Red

      continue
    }

    $BatteryMinutes = $BatteryTest.Minutes
  }

  Write-Section -Title "Requested Sleep Settings"

  Write-Info -Name "Plugged In" -Value (Convert-SleepTimeoutMinutesToText -Minutes $PluggedInMinutes)
  Write-Info -Name "On Battery" -Value (Convert-SleepTimeoutMinutesToText -Minutes $BatteryMinutes)

  Write-Host

  $Confirmation = Read-Host "Apply these power settings? (Y/N)"

  if ($Confirmation.Trim().ToUpper() -ne "Y") {
    Write-Host
    Write-Host "Power configuration cancelled." -ForegroundColor Yellow

    Pause-Application
    return
  }

  Write-Host
  Write-Host "Applying power and sleep settings..." -ForegroundColor Cyan

  $Result = Set-DeploymentSleepTimeouts -PluggedInMinutes $PluggedInMinutes -BatteryMinutes $BatteryMinutes -Confirm:$false

  Write-Host

  switch ($Result.Status) {
    "Updated" {
      Write-Host $Result.Message -ForegroundColor Green
    }

    "Skipped" {
      Write-Host $Result.Message -ForegroundColor Yellow
    }

    default {
      Write-Host $Result.Message -ForegroundColor Red
    }
  }

  if ($Result.Status -in @("Updated", "Skipped")) {
    Write-Host

    Write-Info -Name "Plugged In" -Value (Convert-SleepTimeoutMinutesToText -Minutes $Result.PluggedInMinutes)
    Write-Info -Name "On Battery" -Value (Convert-SleepTimeoutMinutesToText -Minutes $Result.BatteryMinutes)
  }

  Pause-Application

  return $Result
}