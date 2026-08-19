# ============================================================
# UNINSTALLATION QUEUE
# ============================================================

function Write-ApplicationUninstallQueueResult {
  param(
    [Parameter(Mandatory)]
    [ValidateSet("Uninstalled", "Skipped", "Failed")]
    [string]$Status,

    [Parameter(Mandatory)]
    [string]$Message
  )

  $StatusColor = switch ($Status) {
    "Uninstalled" { "Green" }
    "Skipped"     { "Yellow" }
    default       { "Red" }
  }

  Write-Host ("      Status : {0}" -f $Status.ToUpperInvariant()) -ForegroundColor $StatusColor
  Write-Host ("      Reason : {0}" -f $Message)
}

function Confirm-ApplicationUninstall {
  param(
    [Parameter(Mandatory)]
    [string]$ApplicationName
  )

  while ($true) {
    $Confirmation = Read-Host ("Uninstall {0}? (Y/N)" -f $ApplicationName)

    switch ($Confirmation.Trim().ToUpper()) {
      "Y" {
        return $true
      }

      "N" {
        return $false
      }

      default {
        Write-Host "Enter Y to uninstall or N to skip." -ForegroundColor Red
      }
    }
  }
}

function Uninstall-SelectedApplications {
  param(
    [switch]$SkipPause
  )

  $SelectedApplications = @(Get-SelectedApplications)

  if ($SelectedApplications.Count -eq 0) {
    Write-Host
    Write-Host "No applications selected." -ForegroundColor Yellow

    Write-DeploymentLog -Message "Uninstallation requested with no applications selected." -Level "WARNING"

    Pause-Application

    return
  }

  $UninstalledCount = 0
  $SkippedCount = 0
  $FailedCount = 0
  $CurrentNumber = 0

  Write-Host
  Write-Host "Starting uninstallation queue..." -ForegroundColor Cyan
  Write-DeploymentLog -Message ("Uninstallation queue started. Selected applications: {0}" -f $SelectedApplications.Count)

  foreach ($Application in $SelectedApplications) {
    $CurrentNumber++

    Write-Host
    Write-Host ("[{0}/{1}] {2}" -f $CurrentNumber, $SelectedApplications.Count, $Application.Name) -ForegroundColor Cyan

    $IsInstalled = Test-ApplicationInstalled -Application $Application

    if (-not $IsInstalled) {
      $SkippedMessage = ("{0} is not installed." -f $Application.Name)

      Write-ApplicationUninstallQueueResult -Status "Skipped" -Message $SkippedMessage

      $SkippedCount++

      Write-DeploymentLog -Message ("{0} Skipped." -f $SkippedMessage) -Level "INFO"

      continue
    }

    $Confirmed = Confirm-ApplicationUninstall -ApplicationName $Application.Name

    if (-not $Confirmed) {
      $SkippedMessage = ("{0} uninstallation was declined." -f $Application.Name)

      Write-ApplicationUninstallQueueResult -Status "Skipped" -Message $SkippedMessage

      $SkippedCount++

      Write-DeploymentLog -Message $SkippedMessage -Level "INFO"

      continue
    }

    $UninstallationResult = Uninstall-ApplicationByType -Application $Application

    Write-ApplicationUninstallQueueResult -Status $UninstallationResult.Status -Message $UninstallationResult.Message

    switch ($UninstallationResult.Status) {
      "Uninstalled" {
        $UninstalledCount++

        Write-DeploymentLog -Message $UninstallationResult.Message -Level "SUCCESS"
      }

      "Skipped" {
        $SkippedCount++

        Write-DeploymentLog -Message $UninstallationResult.Message -Level "INFO"
      }

      default {
        $FailedCount++
      }
    }
  }

  Write-Host
  Write-Section "Uninstallation Summary"

  Write-Host ("Uninstalled : {0}" -f $UninstalledCount) -ForegroundColor Green
  Write-Host ("Skipped : {0}" -f $SkippedCount) -ForegroundColor Yellow
  Write-Host ("Failed : {0}" -f $FailedCount) -ForegroundColor Red

  $SummaryMessage = ("Uninstallation summary - Uninstalled: {0}; Skipped: {1}; Failed: {2}" -f $UninstalledCount, $SkippedCount, $FailedCount)

  $SummaryLevel = if ($FailedCount -gt 0) {
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
