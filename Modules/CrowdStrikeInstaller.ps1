# ============================================================
# CROWDSTRIKE SENSOR INSTALLER
# ============================================================

function Get-CrowdStrikePackageDirectory {
  return (Join-Path $PSScriptRoot "..\Installers\CrowdStrike")
}

function Get-CrowdStrikeInstallerPath {
  $PackageDirectory = Get-CrowdStrikePackageDirectory

  if (-not (Test-Path -LiteralPath $PackageDirectory -PathType Container)) {
    throw "CrowdStrike package directory was not found."
  }

  $Installers = @(
    Get-ChildItem -LiteralPath $PackageDirectory -File -Filter "*.exe" -ErrorAction Stop | Where-Object {
      $_.VersionInfo.ProductName -eq "CrowdStrike Windows Sensor"
    }
  )

  if ($Installers.Count -eq 0) {
    throw "CrowdStrike Windows Sensor installer was not found."
  }

  if ($Installers.Count -gt 1) {
    throw ("Multiple CrowdStrike Windows Sensor installers were found.")
  }

  return $Installers[0].FullName
}

function Get-CrowdStrikeDeploymentValues {
  $PackageDirectory = Get-CrowdStrikePackageDirectory

  $Readme = Get-ChildItem -LiteralPath $PackageDirectory -File -ErrorAction Stop | Where-Object {
    $_.Name -match "(?i)^readme.*\.txt$"
  } |
  Select-Object -First 1

  if ($null -eq $Readme) {
    throw "CrowdStrike README file was not found."
  }

  $CustomerId = $null
  $ProvisioningToken = $null

  foreach ($Line in Get-Content -LiteralPath $Readme.FullName -ErrorAction Stop) {
    if (
      $Line -match "^\s*Customer\s*ID\s*[:=]\s*(?<Value>.+?)\s*$"
    ) {
      $CustomerId = $Matches.Value.Trim()
      continue
    }

    if (
      $Line -match "^\s*Token\s*[:=]\s*(?<Value>.+?)\s*$"
    ) {
      $ProvisioningToken = $Matches.Value.Trim()
    }
  }

  if ([string]::IsNullOrWhiteSpace($CustomerId)) {
    throw "Customer ID is missing from the CrowdStrike README."
  }

  if ($CustomerId -notmatch "^\w{32}-\w{2}$") {
    throw ("The CrowdStrike Customer ID does not match " + "the expected CID-with-checksum format.")
  }

  if ([string]::IsNullOrWhiteSpace($ProvisioningToken)) {
    throw ("Provisioning token is missing from the " + "CrowdStrike README.")
  }

  return [PSCustomObject]@{
    CustomerId        = $CustomerId
    ProvisioningToken = $ProvisioningToken
    ReadmePath        = $Readme.FullName
  }
}

function Test-CrowdStrikeDeploymentPackage {
  try {
    $InstallerPath = Get-CrowdStrikeInstallerPath
    $DeploymentValues = Get-CrowdStrikeDeploymentValues

    $InstallerItem = Get-Item -LiteralPath $InstallerPath -ErrorAction Stop

    $Result = [PSCustomObject][ordered]@{
      Valid                   = $true
      InstallerName           = $InstallerItem.Name
      InstallerVersion        = $InstallerItem.VersionInfo.ProductVersion
      CustomerIdFound         = $true
      ProvisioningTokenFound  = $true
      CustomerIdLength        = $DeploymentValues.CustomerId.Length
      TokenLength             = $DeploymentValues.ProvisioningToken.Length
      Error                   = $null
    }

    return $Result
  }
  catch {
    $Result = [PSCustomObject][ordered]@{
      Valid                   = $false
      InstallerName           = $null
      InstallerVersion        = $null
      CustomerIdFound         = $false
      ProvisioningTokenFound  = $false
      CustomerIdLength        = 0
      TokenLength             = 0
      Error                   = $_.Exception.Message
    }

    return $Result
  }
}

# ============================================================
# CROWDSTRIKE INTERACTIVE SETUP
# ============================================================

function Test-CrowdStrikeSensorInstalled {
  $FalconService = Get-Service -Name "CSFalconService" -ErrorAction SilentlyContinue

  return ($null -ne $FalconService)
}

function Start-CrowdStrikeInteractiveSetup {
  [CmdletBinding(SupportsShouldProcess = $true)]
  param()

  $ApplicationName = "CrowdStrike Windows Sensor"

  try {
    $AlreadyInstalled = Test-CrowdStrikeSensorInstalled

    if ($AlreadyInstalled -and -not $WhatIfPreference) {
      Write-Host
      Write-Host "$ApplicationName is already installed." -ForegroundColor Yellow

      return [PSCustomObject][ordered]@{
        Application = $ApplicationName
        Status      = "Skipped"
        ExitCode    = $null
        Verified    = $true
        Message     = "CrowdStrike is already installed."
      }
    }

    $CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()

    $CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)

    $IsAdministrator = $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $IsAdministrator -and -not $WhatIfPreference) {
      throw (
        "CrowdStrike setup requires administrator privileges."
      )
    }

    $PackageTest = Test-CrowdStrikeDeploymentPackage

    if (-not $PackageTest.Valid) {
      throw $PackageTest.Error
    }

    $InstallerPath = Get-CrowdStrikeInstallerPath
    $DeploymentValues = Get-CrowdStrikeDeploymentValues

    $CustomerId = $DeploymentValues.CustomerId
    $ProvisioningToken = $DeploymentValues.ProvisioningToken

    if ($CustomerId -match "\s") {
      throw "The CrowdStrike Customer ID contains whitespace."
    }

    if ($ProvisioningToken -match "\s") {
      throw (
        "The CrowdStrike installation token contains whitespace."
      )
    }

    if (
      -not $PSCmdlet.ShouldProcess($ApplicationName, "Open CrowdStrike setup with the CID and token")
    ) {
      return [PSCustomObject][ordered]@{
        Application = $ApplicationName
        Status      = "Preview Only"
        ExitCode    = $null
        Verified    = $false
        Message     = "No setup was opened."
      }
    }

    Write-Host
    Write-Host "Opening CrowdStrike Falcon Sensor Setup..." -ForegroundColor Cyan
    Write-Host "Confirm that the Customer ID and token are populated." -ForegroundColor DarkGray
    Write-Host "You must manually accept the Sensor Terms of Use." -ForegroundColor Yellow
    Write-Host "The deployment tool will wait for setup to close." -ForegroundColor DarkGray

    # /quiet is deliberately excluded so the setup window appears.
    $InstallerArguments = @(
      "/install"
      "/norestart"
      "CID=$CustomerId"
      "ProvToken=$ProvisioningToken"
      "ProvWaitTime=1200000"
    )

    $InstallerProcess = Start-Process -FilePath $InstallerPath -ArgumentList $InstallerArguments -Wait -PassThru -ErrorAction Stop

    $ExitCode = $InstallerProcess.ExitCode

    Start-Sleep -Seconds 3

    $InstallationVerified = Test-CrowdStrikeSensorInstalled

    if ($InstallationVerified) {
      $Status = "Installed"
      $Message = ("CrowdStrike Windows Sensor was installed " + "and the Falcon service was detected.")

      Write-Host
      Write-Host $Message -ForegroundColor Green
    }
    else {
      $Status = "Not Installed"
      $Message = ("CrowdStrike setup closed, but the Falcon " + "service was not detected. Setup may have been cancelled.")

      Write-Host
      Write-Host $Message -ForegroundColor Yellow
    }

    return [PSCustomObject][ordered]@{
      Application = $ApplicationName
      Status      = $Status
      ExitCode    = $ExitCode
      Verified    = $InstallationVerified
      Message     = $Message
    }
  }
  catch {
    $ErrorMessage = $_.Exception.Message

    Write-Host
    Write-Host "CrowdStrike setup failed." -ForegroundColor Red
    Write-Host $ErrorMessage -ForegroundColor Red

    return [PSCustomObject][ordered]@{
      Application = $ApplicationName
      Status      = "Failed"
      ExitCode    = $null
      Verified    = $false
      Message     = $ErrorMessage
    }
  }
}