# ============================================================
# OFFICE 2021 LOP IMG INSTALLER
# ============================================================

function Get-Office2021ImageDirectory {
  $ProjectRoot = $script:ITDeploymentToolRoot

  return Join-Path $ProjectRoot "Installers\IMG\Office2021LOP"
}

function Get-Office2021ImagePath {
  $ImageDirectory = Get-Office2021ImageDirectory
  $ExpectedImageName = "ProPlus2021Retail.img"

  if (-not (Test-Path -LiteralPath $ImageDirectory -PathType Container)) {
    throw "The Office 2021 LOP installer directory was not found."
  }

  $ImagePath = Join-Path $ImageDirectory $ExpectedImageName

  if (-not (Test-Path -LiteralPath $ImagePath -PathType Leaf)) {
    throw ("The expected Office 2021 image was not found: {0}" -f $ExpectedImageName)
  }

  return (Get-Item -LiteralPath $ImagePath -ErrorAction Stop).FullName
}

function Test-Office2021ProPlusRetailInstalled {
  $ConfigurationPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration"
  )

  foreach ($ConfigurationPath in $ConfigurationPaths) {
    $Configuration = Get-ItemProperty -Path $ConfigurationPath -ErrorAction SilentlyContinue

    if ($null -eq $Configuration) {
      continue
    }

    $ProductReleaseIds = @(
      ([string]$Configuration.ProductReleaseIds) -split "," | ForEach-Object {
        $_.Trim()
      }
    )

    if ($ProductReleaseIds -contains "ProPlus2021Retail") {
      return $true
    }
  }

  return $false
}

function Get-InstalledOfficeProductReleaseIds {
  $ConfigurationPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration"
  )

  $DetectedProductIds = New-Object "System.Collections.Generic.List[string]"

  foreach ($ConfigurationPath in $ConfigurationPaths) {
    $Configuration = Get-ItemProperty -Path $ConfigurationPath -ErrorAction SilentlyContinue

    if ($null -eq $Configuration) {
      continue
    }

    $ProductReleaseIds = @([string]$Configuration.ProductReleaseIds -split ",")

    foreach ($ProductId in $ProductReleaseIds) {
      $NormalizedProductId = ([string]$ProductId).Trim()

      if ([string]::IsNullOrWhiteSpace($NormalizedProductId)) {
        continue
      }

      if (-not $DetectedProductIds.Contains($NormalizedProductId)) {
        [void]$DetectedProductIds.Add($NormalizedProductId)
      }
    }
  }

  return @($DetectedProductIds)
}

function Get-Office2021MountedVolume {
  param(
    [Parameter(Mandatory)]
    [string]$ImagePath
  )

  $DiskImage = Get-DiskImage =ImagePath $ImagePath -ErrorAction SilentlyContinue

  if (($null -eq $DiskImage) -or (-not $DiskImage.Attached)) {
    return $null
  }

  return $DiskImage | Get-Volume | Where-Object {
    -not [string]::IsNullOrWhiteSpace(
      [string]$_.DriveLetter
    )
  } | Select-Object -First 1
}

function Test-Office2021DeploymentPackage {
  try {
    $ImagePath = Get-Office2021ImagePath

    return [PSCustomObject]@{
      Valid     = $true
      ImagePath = $ImagePath
      Message   = "Office 2021 LOP image found."
    }
  }
  catch {
    return [PSCustomObject]@{
      Valid     = $false
      ImagePath = $null
      Message   = $_.Exception.Message
    }
  }
}

function Test-Office2021Administrator {
  $AdministratorCommand = Get-Command -Name "Test-Administrator" -ErrorAction SilentlyContinue

  if ($null -ne $AdministratorCommand) {
    return [bool](Test-Administrator)
  }

  $CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()

  $CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)

  return $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Start-Office2021LOPInstallation {
  [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
  param()

  $ImagePath = $null
  $MountedByFunction = $false

  try {
    if ((Test-Office2021ProPlusRetailInstalled) -and (-not $WhatIfPreference)) {
      return [PSCustomObject]@{
        Status  = "Skipped"
        Message = "Microsoft Office Professional Plus 2021 Retail is already installed."
      }
    }

    if (-not $WhatIfPreference) {
      $InstalledOfficeProductIds = @(Get-InstalledOfficeProductReleaseIds)
      $ConflictingOfficeProductIds = @($InstalledOfficeProductIds | Where-Object {
        $_ -ne "ProPlus2021Retail"
      })

      if ($ConflictingOfficeProductIds.Count -gt 0) {
        return [PSCustomObject]@{
          Status  = "Failed"
          Message = ("Office 2021 LOP installation was blocked because " + "another Click-to-Run Office product is installed: {0}" -f ($ConflictingOfficeProductIds -join ", "))
        }
      }
    }

    if ((-not $WhatIfPreference) -and (-not (Test-Office2021Administrator))) {
      throw "Administrator permission is required to install Office 2021."
    }

    $ImagePath = Get-Office2021ImagePath

    if (-not $PSCmdlet.ShouldProcess($ImagePath, "Mount and install Microsoft Office Professional Plus 2021 Retail")) {
      return [PSCustomObject]@{
        Status = "Preview Only"
        Message = "No image was mounted and no setup was opened."
      }
    }

    Unblock-File -LiteralPath $ImagePath -ErrorAction SilentlyContinue

    $DiskImage = Get-DiskImage -ImagePath $ImagePath -ErrorAction SilentlyContinue

    if (($null -eq $DiskImage) -or (-not $DiskImage.Attached)) {
      $DiskImage = Mount-DiskImage -ImagePath $ImagePath -PassThru -ErrorAction Stop

      $MountedByFunction = $true
    }

    $MountedVolume = Get-Office2021MountedVolume -ImagePath $ImagePath

    if ($null -eq $MountedVolume) {
      throw "The mounted Office 2021 drive letter could not be determined."
    }

    $MountedRoot = "{0}:\" -f $MountedVolume.DriveLetter
    $SetupPath = Join-Path $MountedRoot "Setup.exe"

    if (-not (Test-Path -LiteralPath $SetupPath -PathType Leaf)) {
      throw "Setup.exe was not found in the mounted Office 2021 image."
    }

    $SetupSignature = Get-AuthenticodeSignature -FilePath $SetupPath

    if ($SetupSignature.Status -ne "Valid") {
      throw ("Office 2021 Setup.exe has an invalid digital signature: {0}" -f $SetupSignature.Status)
    }

    if (($null -eq $SetupSignature.SignerCertificate) -or ($SetupSignature.SignerCertificate.Subject -notmatch "Microsoft Corporation")) {
      throw "Office 2021 Setup.exe is not signed by Microsoft Corporation."
    }

    Write-Host
    Write-Host "Starting Microsoft Office Professional Plus 2021 Retail installation..." -ForegroundColor Cyan
    Write-Host "Activation will remain manual after installation." -ForegroundColor Yellow

    $SetupProcess = Start-Process -FilePath $SetupPath -ArgumentList "/AUTORUN" -WorkingDirectory $MountedRoot -Wait -PassThru -ErrorAction Stop

    if ($SetupProcess.ExitCode -ne 0) {
      throw ("Office 2021 setup returned exit code {0}." -f $SetupProcess.ExitCode)
    }

    Write-Host
    Write-Host "Verifying Office 2021 installation..." -ForegroundColor Cyan

    $InstallationDetected = $false

    for ($Attempt = 1; $Attempt -le 120; $Attempt++) {
      if (Test-Office2021ProPlusRetailInstalled) {
        $InstallationDetected = $true
        break
      }

      Start-Sleep -Seconds 10
    }

    if (-not $InstallationDetected) {
      throw ("Office setup completed, but ProPlus2021Retail " + "was not detected.")
    }

    return [PSCustomObject]@{
      Status  = "Installed"
      Message = ("Microsoft Office Professional Plus 2021 Retail " + "was installed successfully. Activation remains manual.")
    }
  }

  catch {
    return [PSCustomObject]@{
      Status  = "Failed"
      Message = $_.Exception.Message
    }
  }

  finally {
    if ($MountedByFunction -and (-not [string]::IsNullOrWhiteSpace([string]$ImagePath))) {
      Dismount-DiskImage -ImagePath $ImagePath -ErrorAction SilentlyContinue | Out-Null
    }
  }
}
