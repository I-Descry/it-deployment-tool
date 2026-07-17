# ============================================================
# INSTALLATION ROUTER
# ============================================================

function Test-ApplicationInstallerAvailable {
  param(
    [PSCustomObject]$Application
  )

  $InstallType = [string]$Application.InstallType

  if ([string]::IsNullOrWhiteSpace($InstallType)) {
    return $false
  }

  switch ($InstallType.Trim().ToUpper()) {
    "WINGET" {
      return Test-WingetPackage -Application $Application
    }

    "EXE" {
      return Test-OfflineInstallerFile -Application $Application
    }

    "MSI" {
      return Test-OfflineInstallerFile -Application $Application
    }

    default {
      return $false
    }
  }
}

function Install-ApplicationByType {
  param(
    [PSCustomObject]$Application
  )

  $InstallType = ([string]$Application.InstallType).Trim().ToUpper()

  switch ($InstallType) {
    "WINGET" {
      return Install-ApplicationWithWinget -Application $Application
    }

    "EXE" {
      return Install-ApplicationWithExe -Application $Application
    }

    "MSI" {
      Write-Host
      Write-Host ("$($Application.Name) uses an MSI installer. MSI installation is not enabled yet.") -ForegroundColor Yellow

      Write-DeploymentLog -Message ("{0} uses MSI, but MSI installation is not enabled yet." -f $Application.Name) -Level "WARNING"

      return $false
    }

    default {
      Write-Host
      Write-Host ("Unsupported installation type for $($Application.Name): $InstallType") -ForegroundColor Red

      Write-DeploymentLog -Message ("Unsupported installation type for {0}: {1}" -f $Application.Name, $InstallType) -Level "ERROR"

      return $false
    }
  }
}