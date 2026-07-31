# ============================================================
# COMPUTER NAME CONFIGURATION
# ============================================================

function Get-CurrentComputerName {
  $ComputerName = [string]([System.Environment]::MachineName)

  if ([string]::IsNullOrWhiteSpace($ComputerName)) {
    $ComputerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue

    if ($null -ne $ComputerSystem) {
      $ComputerName = [string]$ComputerSystem.Name
    }
  }

  if ([string]::IsNullOrWhiteSpace($ComputerName)) {
    $HostNameOutput = @(& hostname.exe 2>$null)
    $ComputerName = ($HostNameOutput -join "").Trim()
  }

  if ([string]::IsNullOrWhiteSpace($ComputerName)) {
    $IdentityName = [string]([Security.Principal.WindowsIdentity]::GetCurrent().Name)

    if ($IdentityName -match "^(?<Computer>[^\\]+)\\") {
      $ComputerName = $Matches.Computer
    }
  }

  if ([string]::IsNullOrWhiteSpace($ComputerName)) {
    return "Unknown"
  }

  return $ComputerName.Trim().ToUpperInvariant()
}

function Test-DeploymentComputerName {
  param(
    [Parameter(Mandatory)]
    [string]$ComputerName
  )

  $NormalizedName = $ComputerName.Trim().ToUpper()

  if ([string]::IsNullOrWhiteSpace($NormalizedName)) {
    return [PSCustomObject]@{
      Valid        = $false
      ComputerName = $NormalizedName
      Message      = "The computer name cannot be empty."
    }
  }

  if ($NormalizedName.Length -gt 15) {
    return [PSCustomObject]@{
      Valid        = $false
      ComputerName = $NormalizedName
      Message      = "The computer name cannot exceed 15 characters."
    }
  }

  if ($NormalizedName -notmatch "^[A-Z0-9]+-[A-Z0-9]+$") {
    return [PSCustomObject]@{
      Valid        = $false
      ComputerName = $NormalizedName
      Message      = ("Use the POSITION-NAME format. Only letters, " + "numbers, and one hyphen are allowed.")
    }
  }

  return [PSCustomObject]@{
    Valid        = $true
    ComputerName = $NormalizedName
    Message      = "The computer name is valid."
  }
}

function Set-DeploymentComputerName {
  [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
  param(
    [Parameter(Mandatory)]
    [string]$NewName
  )

  try {
    $Validation = Test-DeploymentComputerName -ComputerName $NewName

    if (-not $Validation.Valid) {
      return [PSCustomObject]@{
        Status       = "Failed"
        ComputerName = $Validation.ComputerName
        Message      = $Validation.Message
      }
    }

    $NormalizedName = $Validation.ComputerName
    $CurrentName = Get-CurrentComputerName

    if ($CurrentName -eq $NormalizedName) {
      return [PSCustomObject]@{
        Status       = "Skipped"
        ComputerName = $NormalizedName
        Message      = "The computer already uses this name."
      }
    }

    if ((-not $WhatIfPreference) -and (-not (Test-CurrentProcessAdministrator))) {
      return [PSCustomObject]@{
        Status       = "Failed"
        ComputerName = $NormalizedName
        Message      = ("Administrator permission is required to rename the computer.")
      }
    }

    if (-not $PSCmdlet.ShouldProcess($CurrentName, "Rename computer to $NormalizedName")) {
      return [PSCustomObject]@{
        Status       = "Preview Only"
        ComputerName = $NormalizedName
        Message      = "The computer name was not changed."
      }
    }

    Rename-Computer -NewName $NormalizedName -Force -ErrorAction Stop

    $LoggingCommand = Get-Command -Name "Write-DeploymentLog" -ErrorAction SilentlyContinue

    if ($null -ne $LoggingCommand) {
      Write-DeploymentLog -Message ("Computer renamed from {0} to {1}. Restart required." -f $CurrentName, $NormalizedName) -Level "INFO"
    }

    return [PSCustomObject]@{
      Status       = "Renamed"
      ComputerName = $NormalizedName
      Message      = ("The computer was renamed successfully. " + "Restart Windows to apply the new name.")
    }
  }

  catch {
    return [PSCustomObject]@{
      Status       = "Failed"
      ComputerName = $NewName
      Message      = $_.Exception.Message
    }
  }
}

function Start-ComputerRenameWizard {
  Clear-Host

  Write-Title -Title "RENAME COMPUTER"
  Write-Section -Title "Current Configuration"

  $CurrentName = Get-CurrentComputerName

  Write-Info -Name "Current Name" -Value $CurrentNam
  Write-Section -Title "Naming Standard"

  Write-Host " Format       : POSITION-NAME"
  Write-Host " Example      : IT04-JP"
  Write-Host " Maximum      : 15 characters"
  Write-Host " Allowed      : Letters, numbers, and one hyphen"

  Write-Host

  $RequestedName = Read-Host "Enter the new computer name or press ENTER to cancel"

  if ([string]::IsNullOrWhiteSpace($RequestedName)) {
    Write-Host
    Write-Host "Computer rename cancelled." -ForegroundColor Yellow

    Pause-Application
    return
  }

  $Validation = Test-DeploymentComputerName -ComputerName $RequestedName

  if (-not $Validation.Valid) {
    Write-Host
    Write-Host $Validation.Message -ForegroundColor Red

    Pause-Application
    return
  }

  $NewName = $Validation.ComputerName

  Write-Section -Title "Rename Preview"
  Write-Info -Name "Current Name" -Value $CurrentName
  Write-Info -Name "New Name" -Value $NewName

  Write-Host

  $Confirmation = Read-Host "Rename this computer? (Y/N)"

  if ($Confirmation.Trim().ToUpper() -ne "Y") {
    Write-Host
    Write-Host "Computer rename cancelled." -ForegroundColor Yellow

    Pause-Application
    return
  }

  $RenameResult = Set-DeploymentComputerName -NewName $NewName -Confirm:$false

  Write-Host

  switch ($RenameResult.Status) {
    "Renamed" {
      Write-Host -Object $RenameResult.Message -ForegroundColor Green
    }

    "Skipped" {
      Write-Host -Object $RenameResult.Message -ForegroundColor Yellow
    }

    "Preview Only" {
      Write-Host -Object $RenameResult.Message -ForegroundColor Yellow
    }

    default {
      Write-Host -Object $RenameResult.Message -ForegroundColor Red
    }
  }

  Pause-Application
}