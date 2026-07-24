# ============================================================
# OFFICE 2024 ISO INSTALLER
# ============================================================

function Get-OfficeIsoDirectory {
  return (Join-Path $PSScriptRoot "..\Installers\Office2024")
}

function Get-OfficeIsoPath {
  $OfficeIsoDirectory = Get-OfficeIsoDirectory

  if (-not (Test-Path -LiteralPath $OfficeIsoDirectory -PathType Container)) {
    throw "Office 2024 installer directory was not found."
  }

  $ExpectedIsoName = "ODT2024s.ISO"

  $OfficeIsoPath = Join-Path $OfficeIsoDirectory $ExpectedIsoName

  if (-not (Test-Path -LiteralPath $OfficeIsoPath -PathType Leaf)) {
    throw ("The expected Office ISO was not found: {0}" -f $ExpectedIsoName)
  }

  return (Get-Item -LiteralPath $OfficeIsoPath -ErrorAction Stop).Fullname
}

function Test-Office2024Installed {
  $RegistryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration"
  )

  foreach ($RegistryPath in $RegistryPaths) {
    $Configuration = Get-ItemProperty -LiteralPath $RegistryPath -ErrorAction SilentlyContinue

    if ($null -eq $Configuration) {
      continue
    }

    $ProductReleaseIds = ([string]$Configuration.ProductReleaseIds).Trim()

    if ($ProductReleaseIds -match "(?i)(^|,)Standard2024Volume(,|$)") {
      return $true
    }
  }

  return $false
}

function Get-OfficeMountedVolume {
  param(
    [Parameter(Mandatory)]
    $DiskImage
  )

  for ($Attempt = 1; $Attempt -le 10; $Attempt++) {
    $MountedVolume = $DiskImage | Where-Object {
      -not [string]::IsNullOrWhiteSpace([string]$_.DriveLetter)
    } | Select-Object -First 1

    if ($null -ne $MountedVolume) {
      return $MountedVolume
    }

    Start-Sleep -Milliseconds 500
  }

  throw "The mounted Office ISO drive letter could not be determined."
}

function Start-Office2024Installation {
  [CmdletBinding(SupportsShouldProcess = $true)]
  param()

  $ApplicationName = "Microsoft Office LTSC Standard 2024"
  $OfficeIsoPath = $null
  $MountedByFunction = $false
  $InstallerExitCode = $null

  try {
    $AlreadyInstalled = Test-Office2024Installed

    if ($AlreadyInstalled -and -not $WhatIfPreference) {
      Write-Host
      Write-Host "$ApplicationName is already installed." -ForegroundColor Yellow

      return [PSCustomObject][ordered]@{
        Application = $ApplicationName
        Status      = "Skipped"
        ExitCode    = $null
        Verified    = $true
        Message     = "Office LTSC Standard 2024 is already installed"
      }
    }

    $CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)
    $IsAdministrator = $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $IsAdministrator -and -not $WhatIfPreference) {
      throw "Office 2024 installation requires administrator privileges."
    }

    $OfficeIsoPath = Get-OfficeIsoPath

    if (-not $PSCmdlet.ShouldProcess($ApplicationName, "Mount the Office ISO and run setup.exe /configure office2024.xml")) {
      return [PSCustomObject][ordered]@{
        Application = $ApplicationName
        Status      = "Preview Only"
        ExitCode    = $null
        Verified    = $false
        Message     = "No Office installation was performed."
      }
    }

    Write-Host
    Write-Host "Preparing Microsoft Office LTSC Standard 2024..." -ForegroundColor Cyan

    Unblock-File -LiteralPath $OfficeIsoPath -ErrorAction SilentlyContinue

    $DiskImage = Get-DiskImage -ImagePath $OfficeIsoPath -ErrorAction SilentlyContinue

    if ($null -eq $DiskImage -or (not $DiskImage.Attached)) {
      $DiskImage = Mount-DiskImage -ImagePath $OfficeIsoPath -PassThru -ErrorAction Stop

      $MountedByFunction = $true
    }

    $MountedVolume = Get-OfficeMountedVolume -DiskImage $DiskImage
    $MountedRoot = "{0}:\" -f $MountedVolume.DriveLetter
    $SetupPath = Join-Path $MountedRoot "setup.exe"
    $ConfigurationPath = Join-Path $MountedRoot "office2024.xml"

    if (-not (Test-Path -LiteralPath $SetupPath -PathType Leaf)) {
      throw "setup.exe was not found inside the Office ISO."
    }

    if (-not (Test-Path -LiteralPath $ConfigurationPath -PathType Leaf)) {
      throw "office2024.xml was not found inside the Office ISO."
    }

    Write-Host
    Write-Host "Starting Office installation..." -ForegroundColor Cyan
    Write-Host "Office activation will remain manual after installation." -ForegroundColor Yellow

    Write-DeploymentLog -Level "INFO" -Message ("{0} installation started from the Office ISO." -f $ApplicationName)

    $InstallerArguments = ("/configure `"{0}`"" -f $ConfigurationPath)

    $InstallerProcess = Start-Process -FilePath $SetupPath -ArgumentList $InstallerArguments -WorkingDirectory $MountedRoot -Wait -PassThru -ErrorAction Stop

    $InstallerExitCode = $InstallerProcess.ExitCode

    if ($InstallerExitCode -ne 0) {
      throw ("Office setup exited with code {0}." -f $InstallerExitCode)
    }

    Write-Host
    Write-Host "Verifying Office installation..." -ForegroundColor DarkGray

    $InstallationVerified = $false

    for ($Attempt = 1; $Attempt -le 12; $Attempt++) {
      if (Test-Office2024Installed) {
        $InstallationVerified = $true
        break
      }

      Start-Sleep -Seconds 5
    }

    if ($InstallationVerified) {
      $Status = "Installed"
      $Message = ("Microsoft Office LTSC Standard 2024 was " + "installed successfully. Product activation is still required.")

      Write-Host
      Write-Host $Message -ForegroundColor Green

      Write-DeploymentLog -Level "SUCCESS" -Message $Message
    }
    else {
      $Status = "Completed"
      $Message = ("Office setup completed, but Office LTSC Standard 2024 " + "was not detected yet.")

      Write-Host
      Write-Host $Message -ForegroundColor Yellow

      Write-DeploymentLog -Level "WARNING" -Message $Message
    }

    return [PSCustomObject][ordered]@{
      Application = $ApplicationName
      Status      = $Status
      ExitCode    = $InstallerExitCode
      Verified    = $InstallationVerified
      Message     = $Message
    }
  }

  catch {
    $CaughtError = $_

    $ErrorMessage = [string]$CaughtError.Exception.Message

    if ([string]::IsNullOrWhiteSpace($ErrorMessage)) {
      $ErrorMessage = [string]$CaughtError
    }

    if ([string]::IsNullOrWhiteSpace($ErrorMessage)) {
      $ErrorMessage = $CaughtError.Exception.GetType().FullName
    }

    Write-Host
    Write-Host "Detailed error information:" -ForegroundColor Yellow
    Write-Host ("Type       : {0}" -f $CaughtError.Exception.GetType().FullName)
    Write-Host ("Line       : {0}" -f $CaughtError.InvocationInfo.ScriptLineNumber)
    Write-Host ("Statement  : {0}" -f $CaughtError.InvocationInfo.Line.Trim())
    Write-Host ("Message    : {0}" -f $ErrorMessage)
  }

  finally {
    if ($MountedByFunction -and -not [string]::IsNullOrWhiteSpace(
      [string]$OfficeIsoPath
    )) {
      Dismount-DiskImage -ImagePath $OfficeIsoPath -ErrorAction SilentlyContinue | Out-Null
    }
  }
}