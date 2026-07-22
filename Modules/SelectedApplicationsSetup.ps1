# ============================================================
# SELECTED APPLICATIONS SETUP
# ============================================================

function Show-SelectedApplicationsPreview {
  param(
    [Parameter(Mandatory)]
    [object[]]$Applications
  )

  Clear-Host
  Write-Title "SELECTED APPLICATIONS PREVIEW"

  Write-Host
  Write-Section "Applications to Process"

  for ($Index = 0; $Index -lt $Applications.Count; $Index++) {
    $Application = $Applications[$Index]
    $ApplicationNumber = $Index + 1

    $InstallationStatus = if ($Application.Installed) {
      "Installed"
    }
    else {
      "Not Installed"
    }

    Write-Host ("{0,2}. {1}" -f $ApplicationNumber, $Application.Name)
    Write-Host (
      "     Type: {0} | Category: {1} | Status: {2}" -f $Application.InstallType, $Application.Category, $InstallationStatus) -ForegroundColor DarkGray
  }

  Write-Host
  Write-Host "------------------------------------------------------------"
  Write-Host ("Total selected applications: {0}" -f $Applications.Count) -ForegroundColor Cyan
  Write-Host ("Applications already installed will be skipped.") -ForegroundColor DarkGray
}

function Confirm-SelectedApplicationsInstallation {
  while ($true) {
    Write-Host
    
    $Confirmation = Read-Host "Continue with the selected applications? (Y/N)"

    switch ($Confirmation.Trim().ToUpper()) {
      "Y" {
        return $true
      }
      "N" {
        return $false
      }

      default {
        Write-Host
        Write-Host "Enter Y to continue or N to cancel." -ForegroundColor Red
      }
    }
  }
}

function Start-SelectedApplicationsSetup {
  $SelectedApplications = @(Get-SelectedApplications)

  if ($SelectedApplications.Count -eq 0) {
    Write-Host
    Write-Host "No applications selected." -ForegroundColor Yellow

    Write-DeploymentLog -Level "WARNING" -Message "Installation requested with no applications selected."

    Pause-Application
    
    return $false
  }

  Show-SelectedApplicationsPreview -Applications $SelectedApplications
    $Confirmed = Confirm-SelectedApplicationsInstallation

    if (-not $Confirmed) {
      Write-DeploymentLog -Level "INFO" -Message "Selected applications installation was cancelled."

      Write-Host
      Write-Host "Installation cancelled." -ForegroundColor Yellow

      Pause-Application

      return $false
    }

    Write-DeploymentLog -Level "INFO" -Message (
      "Selected applications installation confirmed with {0} application(s)." -f $SelectedApplications.Count
    )

    Install-SelectedApplications -SkipPause

    Write-Host
    Write-Host "Refreshing installed application status..." -ForegroundColor DarkGray

    Update-ApplicationInstallationStatus

    Write-Host "Installed application status refreshed." -ForegroundColor Green

    Pause-Application

    return $true
  }