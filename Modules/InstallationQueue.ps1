# ============================================================
# INSTALLATION QUEUE
# ============================================================

function Install-SelectedApplications {
  param(
    [switch]$SkipPause
  )

  $SelectedApplications = @(Get-SelectedApplications)

  if ($SelectedApplications.Count -eq 0) {
    Write-Host
    Write-Host "No applications selected." -ForegroundColor Yellow

    Write-DeploymentLog -Message "Installation requested with no applications selected." -Level "WARNING"

    Pause-Application

    return
  }

  $InstalledCount = 0
  $SkippedCount = 0
  $FailedCount = 0
  $NotFoundCount = 0
  $CurrentNumber = 0

  Write-Host
  Write-Host "Starting installation queue..." -ForegroundColor Cyan
  Write-DeploymentLog -Message ("Installation queue started. Selected applications: {0}" -f $SelectedApplications.Count)

  foreach ($Application in $SelectedApplications) {
    $CurrentNumber++

    Write-Host
    Write-Host ("[{0}/{1}] {2}" -f $CurrentNumber, $SelectedApplications.Count, $Application.Name) -ForegroundColor Cyan

    $AlreadyInstalled = Test-ApplicationInstalled -Application $Application

    if ($AlreadyInstalled) {
      Write-Host ("{0} is already installed. Skipping." -f $Application.Name) -ForegroundColor Yellow

      $SkippedCount++

      Write-DeploymentLog -Message ("{0} is already installed. Skipped." -f $Application.Name) -Level "INFO"

      continue
    }

    Write-Host "Checking installer..." -NoNewline

    $InstallerAvailable = Test-ApplicationInstallerAvailable -Application $Application

    if (-not $InstallerAvailable) {
      Write-Host " [ NOT FOUND ]" -ForegroundColor Red

      $NotFoundCount++

      Write-DeploymentLog -Message ("Installer not found or unavailable: {0}" -f $Application.Name) -Level "ERROR"

      continue
    }

    Write-Host " [ OK ]" -ForegroundColor Green

    $InstallSucceeded = Install-ApplicationByType -Application $Application

    if ($InstallSucceeded) {
      $InstalledCount++
    }
    else {
      $FailedCount++
    }
  }

  Write-Host
  Write-Section "Installation Summary"

  Write-Host ("Installed : {0}" -f $InstalledCount) -ForegroundColor Green
  Write-Host ("Skipped : {0}" -f $SkippedCount) -ForegroundColor Yellow
  Write-Host ("Failed : {0}" -f $FailedCount) -ForegroundColor Red
  Write-Host ("Not Found : {0}" -f $NotFoundCount) -ForegroundColor Red

  $SummaryMessage = ("Installation summary - Installed: {0}; Skipped: {1}; Failed: {2}; Not Found: {3}" -f
    $InstalledCount,
    $SkippedCount,
    $FailedCount,
    $NotFoundCount
  )

  $SummaryLevel = if (
    ($FailedCount -gt 0) -or ($NotFoundCount -gt 0)
  ) {
    "WARNING"
  }
  else {
    "SUCCESS"
  }

  Write-DeploymentLog -Message $SummaryMessage -Level $SummaryLevel

  if (-not $SkipPause) {
    Pause-Application
  }
}