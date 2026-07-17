# ============================================================
# APPLICATION INSTALLER
# ============================================================

function Get-WingetInstallArguments {
  param(
    [PSCustomObject]$Application
  )

  return @(
    "install"
    "--id"
    $Application.Winget
    "--exact"
    "--source"
    "winget"
    "--silent"
    "--accept-package-agreements"
    "--accept-source-agreements"
    "--disable-interactivity"
  )
}

function Test-WingetPackage {
  param(
    [PSCustomObject]$Application
  )

  $WingetArguments = @(
    "show"
    "--id"
    $Application.Winget
    "--exact"
    "--source"
    "winget"
    "--accept-source-agreements"
    "--disable-interactivity"
  )

  & winget @WingetArguments *> $null

  return ($LASTEXITCODE -eq 0)
}

function Test-ApplicationInstalled {
  param(
    [PSCustomObject]$Application
  )

  $RegistryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
  )

  foreach ($RegistryPath in $RegistryPaths) {
    $InstalledApplication = Get-ItemProperty -Path $RegistryPath -ErrorAction SilentlyContinue |
    Where-Object {
      $_.DisplayName -and
      $_.DisplayName.Trim() -like "$($Application.Name)*"
    } |
    Select-Object -First 1

    if ($null -ne $InstalledApplication) {
      return $true
    }
  }

  return $false
}

function Install-ApplicationWithWinget {
  param(
    [PSCustomObject]$Application
  )

  Write-Host
  Write-Host "Installing $($Application.Name)..." -ForegroundColor Cyan

  $WingetArguments = Get-WingetInstallArguments -Application $Application

  Write-DeploymentLog -Message ("Installation started: {0} ({1})" -f $Application.Name, $Application.Widget)

  & winget @WingetArguments | Out-Host

  $ExitCode = $LASTEXITCODE
 
  if ($ExitCode -eq 0) {
    Write-Host
    Write-Host "$($Application.Name) installed successfully." -ForegroundColor Green

    Write-DeploymentLog -Message "$($Application.Name) installed successfully." -Level "SUCCESS"

    return $true
  }

  Write-Host
  Write-Host ("$($Application.Name) failed. Exit code: {0}" -f $ExitCode) -ForegroundColor Red

  Write-DeploymentLog -Message ("{0} installation failed. Exit code: {1}" -f $Application.Name, $ExitCode) -Level "ERROR"

  return $false
}

function Install-SelectedApplications {
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
  $FailedCOunt = 0
  $NotFoundCount = 0
  $CurrentNumber = 0

  Write-Host
  Write-Host "Starting installation queue..." -ForegroundColor Cyan

  Write-DeploymentLog -Message ("Installation queue started. Selected applications: {0}" -f $SelectedApplications.Count)

  foreach ($Application in $SelectedApplications) {
    $CurrentNumber++

    Write-Host
    Write-Host ("[{0}/{1}] {2}" -f $CurrentNumber, $SelectedApplications.Count, $Application.Name) -ForegroundColor Cyan
    Write-Host "Checking package..." -NoNewline
    
    $PackageExists = Test-WinGetPackage -Application $Application

    if (-not $PackageExists) {
      Write-Host " [ NOT FOUND ]" -ForegroundColor Red
      $NotFoundCount++

      Write-DeploymentLog -Message ("Package not found: {0} ({1})" -f $Application.Name, $Application.Winget) -Level "ERROR"

      continue
    }

    Write-Host " [ OK ]" -ForegroundColor Green
    
    $AlreadyInstalled = Test-ApplicationInstalled -Application $Application

    if ($AlreadyInstalled) {
      Write-Host ("$($Application.Name) is already installed. Skipping.") -ForegroundColor Yellow
      $SkippedCount++

      Write-DeploymentLog -Message "$($Application.Name) is already installed. Skipped." -Level "WARNING"

      continue
    }

    $InstallSucceeded = Install-ApplicationWithWinget -Application $Application
    
    if ($InstallSucceeded) {
      $InstalledCount++
    }
    else {
      $FailedCount++
    }
  }

  Write-Host
  Write-Section "Installed Summary"

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

  Pause-Application
}