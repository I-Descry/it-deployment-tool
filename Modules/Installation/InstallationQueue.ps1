# ============================================================
# INSTALLATION QUEUE
# ============================================================

function Write-ApplicationQueueResult {
  param(
    [Parameter(Mandatory)]
    [ValidateSet("Installed", "Skipped", "Blocked", "Failed", "Not Found")]
    [string]$Status,

    [Parameter(Mandatory)]
    [string]$Message
  )

  $StatusColor = switch ($Status) {
    "Installed" { "Green" }
    "Skipped"   { "Yellow" }
    "Blocked"   { "Yellow" }
    default     { "Red" }
  }

  Write-Host ("      Status : {0}" -f $Status.ToUpperInvariant()) -ForegroundColor $StatusColor
  Write-Host ("      Reason : {0}" -f $Message)
}

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
  $BlockedCount = 0
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
      $SkippedMessage = ("{0} is already installed." -f $Application.Name)

      Write-ApplicationQueueResult -Status "Skipped" -Message $SkippedMessage

      $SkippedCount++

      Write-DeploymentLog -Message ("{0} Skipped." -f $SkippedMessage) -Level "INFO"

      continue
    }

    $BlockingResult = Resolve-BlockingApplicationProcesses -Application $Application

    if ($BlockingResult.Status -eq "Blocked") {
      $BlockingProcessText = @($BlockingResult.ProcessNames) -join ", "

      $BlockedMessage = ("{0} was skipped because these processes are still running: {1}" -f $Application.Name, $BlockingProcessText)

      Write-ApplicationQueueResult -Status "Blocked" -Message $BlockedMessage

      $BlockedCount++

      Write-DeploymentLog -Message $BlockedMessage -Level "WARNING"

      continue
    }

    Write-Host "Checking installer..." -NoNewline

    # A cloud-sourced application (CrowdStrike, Office LTSC 2024, Office 2021 LOP, SAP GUI) correctly reports unavailable here on a fresh device that has not fetched its package yet -- that is not the same as genuinely unavailable, since Install-ApplicationByType fetches it automatically before installing. Only short-circuits to Not Found when there is neither a local package nor a configured cloud source to fetch one from.
    $InstallerAvailable = Test-ApplicationInstallerAvailable -Application $Application
    $CloudSourceConfigured = Test-CloudInstallerConfigured -Application $Application

    if ((-not $InstallerAvailable) -and (-not $CloudSourceConfigured)) {
      Write-Host " [ NOT FOUND ]" -ForegroundColor Red

      $NotFoundMessage = ("Installer was not found or is unavailable for {0}." -f $Application.Name)

      Write-ApplicationQueueResult -Status "Not Found" -Message $NotFoundMessage

      $NotFoundCount++

      Write-DeploymentLog -Message $NotFoundMessage -Level "ERROR"

      continue
    }

    Write-Host " [ OK ]" -ForegroundColor Green

    $InstallationResult = Install-ApplicationByType -Application $Application

    Write-ApplicationQueueResult -Status $InstallationResult.Status -Message $InstallationResult.Message

    switch ($InstallationResult.Status) {
      "Installed" {
        $InstalledCount++
      }

      "Skipped" {
        $SkippedCount++

        Write-DeploymentLog -Message $InstallationResult.Message -Level "INFO"
      }

      default {
        $FailedCount++
      }
    }
  }

  Write-Host
  Write-Section "Installation Summary"

  Write-Host ("Installed : {0}" -f $InstalledCount) -ForegroundColor Green
  Write-Host ("Skipped : {0}" -f $SkippedCount) -ForegroundColor Yellow
  Write-Host ("Blocked : {0}" -f $BlockedCount) -ForegroundColor Yellow
  Write-Host ("Failed : {0}" -f $FailedCount) -ForegroundColor Red
  Write-Host ("Not Found : {0}" -f $NotFoundCount) -ForegroundColor Red

  $SummaryMessage = ("Installation summary - Installed: {0}; Skipped: {1}; Blocked: {2}; Failed: {3}; Not Found: {4}" -f
    $InstalledCount,
    $SkippedCount,
    $BlockedCount,
    $FailedCount,
    $NotFoundCount
  )

  $SummaryLevel = if(($BlockedCount -gt 0) -or ($FailedCount -gt 0) -or ($NotFoundCount -gt 0)) {
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