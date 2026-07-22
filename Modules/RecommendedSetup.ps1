# ============================================================
# RECOMMENDED APPLICATIONS SETUP
# ============================================================

function Show-RecommendedApplicationsPreview {
  Clear-Host
  Write-Title "RECOMMENDED APPLICATIONS SETUP"

  $RecommendedApplications = @(
    Get-RecommendedApplications
  )

  if ($RecommendedApplications.Count -eq 0) {
    Write-Host
    Write-Host "No recommended applications are configured." -ForegroundColor Yellow

    return @()
  }

  Write-Host
  Write-Section "Applications to Process"

  $ApplicationNumber = 1

  foreach ($Application in $RecommendedApplications) {
    Write-Host ("{0,2}. {1}" -f $ApplicationNumber, $Application.Name)
    Write-Host ("Type: {0} | Category: {1}" -f $Application.InstallType, $Application.Category) -ForegroundColor DarkGray

    $ApplicationNumber ++
  }

  Write-Host
  Write-Host "------------------------------------------------------------"

  Write-Host ("Total recommended applications: {0}" -f $RecommendedApplications.Count) -ForegroundColor Cyan

  return $RecommendedApplications
}

function Confirm-RecommendedApplicationsInstallation {
  while ($true) {
    Write-Host
    $Confirmation = Read-Host "Continue with installation? (Y/N)"

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

function Start-RecommendedApplicationsSetup {
  $RecommendedApplications = @(
    Show-RecommendedApplicationsPreview
  )

  if ($RecommendedApplications.Count -eq 0) {
    Pause-Application
    return
  }

  $Confirmed = Confirm-RecommendedApplicationsInstallation

  if (-not $Confirmed) {
    Write-DeploymentLog -Level "INFO" -Message "Recommended applications setup was cancelled."

    Write-Host
    Write-Host "Recommended setup cancelled." -ForegroundColor Yellow

    Pause-Application
    return
  }

  $RecommendedCount = Select-RecommendedApplications

  Write-DeploymentLog -Level "INFO" -Message ("Recommended applications setup confirmed with {0} application(s)." -f $RecommendedCount)

  Install-SelectedApplications
}