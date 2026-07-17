# ============================================================
# WINGET INSTALLER
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