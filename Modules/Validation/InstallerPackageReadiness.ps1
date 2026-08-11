# ============================================================
# INSTALLER PACKAGE READINESS
# ============================================================

function Get-InstallerPackageReadiness {
  param(
    [Parameter(Mandatory)]
    [object[]]$Applications
  )

  $PackageInstallTypes = @(
    "EXE"
    "MSI"
    "CROWDSTRIKE"
    "OFFICEISO"
    "OFFICE2021IMG"
  )

  $Results = [System.Collections.Generic.List[object]]::new()

  foreach ($Application in $Applications) {
    $InstallType = ([string]$Application.InstallType).Trim().ToUpperInvariant()

    if ($InstallType -notin $PackageInstallTypes) {
      continue
    }

    $Ready = $false
    $Message = ""

    try {
      $Ready = [bool](Test-ApplicationInstallerAvailable -Application $Application)

      if ($Ready) {
        $Message = "Installer package is available."
      }
      else {
        $Message = "Installer package is missing or invalid."
      }
    }

    catch {
      $Ready = $false
      $Message = $_.Exception.Message
    }

    [void]$Results.Add([PSCustomObject]@{
      Name        = $Application.Name
      InstallType = $Application.InstallType
      Status      = if ($Ready) {
        "READY"
      }
      else {
        "MISSING"
      }
      Message     = $Message
    })
  }

  return @($Results)
}

function Show-InstallerPackageReadiness {
  param(
    [Parameter(Mandatory)]
    [object[]]$Results
  )

  Write-Host
  Write-Host "Installer Package Status" -ForegroundColor Cyan

  Write-Host "------------------------------------------------------------"

  foreach ($Result in $Results) {
    $StatusColor = if ($Result.Status -eq "READY") {
      "Green"
    }
    else {
      "Red"
    }

    Write-Host ("{0,-45}" -f $Result.Name) -NoNewline
    Write-Host ("[ {0} ]" -f $Result.Status) -ForegroundColor $StatusColor
  }

  Write-Host
}