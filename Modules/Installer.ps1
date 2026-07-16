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

function Install-ApplicationWithWinget {
  param(
    [PSCustomObject]$Application
  )

  Write-Host
  Write-Host "Installing $($Application.Name)..." -ForegroundColor Cyan

  $WingetArguments = Get-WingetInstallArguments -Application $Application

  & winget @WingetArguments

  $ExitCode = $LASTEXITCODE
 
  if ($ExitCode -eq 0) {
    Write-Host
    Write-Host "$($Application.Name) installed successfully." -ForegroundColor Green

    return $true
  }

  Write-Host
  Write-Host ("$($Application.Name) failed. Exit code: {0}" -f $ExitCode) -ForegroundColor Red

  return $false
}
function Install-SelectedApplications {
  $SelectedApplications = @(Get-SelectedApplications)

  if ($SelectedApplications.Count -eq 0) {
    Write-Host
    Write-Host "No applications selected." -ForegroundColor Yellow
    Pause-Application

    return
  }

  if ($SelectedApplications.Count -gt 1) {
    Write-Host
    Write-Host "For this test, select only one application." -ForegroundColor Yellow
    Pause-Application

    return
  }

  $Application = $SelectedApplications[0]

  Write-Host
  Write-Host "Checking $($Application.Name)..." -ForegroundColor Cyan

  $PackageExists = Test-WingetPackage -Application $Application

  if (-not $PackageExists) {
    Write-Host
    Write-Host "$($Application.Name) was not found in Winget." -ForegroundColor Red
    Pause-Application

    return
  }

  [void](Install-ApplicationWithWinget -Application $Application)

  Pause-Application
}