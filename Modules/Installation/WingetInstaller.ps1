# ============================================================
# WINGET INSTALLER
# ============================================================

function Get-WingetScopeArguments {
  param(
    [PSCustomObject]$Application
  )

  $ConfiguredScope = [string]$Application.WingetScope

  if ([string]::IsNullOrWhiteSpace($ConfiguredScope)) {
    return @()
  }

  $NormalizedScope = $ConfiguredScope.Trim().ToLowerInvariant()

  if ($NormalizedScope -notin @("user", "machine")) {
    throw ("Invalid WinGet scope for {0}: {1}. " + "Supported values are user and machine.") -f $Application.Name, $ConfiguredScope
  }

  return @("--scope"
    $NormalizedScope)
}

function Get-WingetInstallArguments {
  param([PSCustomObject]$Application)

  $WingetArguments = @(
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

  $WingetArguments += @(Get-WingetScopeArguments -Application $Application)

  return $WingetArguments
}

function Get-WingetUninstallArguments {
  param([PSCustomObject]$Application)

  $WingetArguments = @(
    "uninstall"
    "--id"
    $Application.Winget
    "--exact"
    "--source"
    "winget"
    "--silent"
    "--accept-source-agreements"
    "--disable-interactivity"
  )

  $WingetArguments += @(Get-WingetScopeArguments -Application $Application)

  return $WingetArguments
}

function Test-WingetPackage {
  param([PSCustomObject]$Application)

  $WingetArguments = @(
    "show"
    "--id"
    $Application.winget
    "--exact"
    "--source"
    "winget"
    "--accept-source-agreements"
    "--disable-interactivity"
  )

  $WingetArguments += @(Get-WingetScopeArguments -Application $Application)

  & winget @WingetArguments *> $null

  return ($LASTEXITCODE -eq 0)
}

function Install-ApplicationWithWinget {
  param([PSCustomObject]$Application)

  Write-Host
  Write-Host "Installing $($Application.Name)..." -ForegroundColor Cyan

  try {
    $WingetArguments = Get-WingetInstallArguments -Application $Application
  }

  catch {
    Write-Host
    Write-Host $_.Exception.Message -ForegroundColor Red

    Write-DeploymentLog -Message $_.Exception.Message -Level "ERROR"

    return [PSCustomObject]@{ Status = "Failed"; Message = $_.Exception.Message }
  }

  Write-DeploymentLog -Message ("Installation started: {0} ({1})" -f $Application.Name, $Application.Winget)

  & winget @WingetArguments | Out-Host

  $ExitCode = $LASTEXITCODE

  if ($ExitCode -eq 0) {
    Write-Host
    Write-Host ("$($Application.Name) installed successfully.") -ForegroundColor Green

    Write-DeploymentLog -Message "$($Application.Name) installed successfully." -Level "SUCCESS"

    return [PSCustomObject]@{ Status = "Installed"; Message = "$($Application.Name) installed successfully." }
  }

  Write-Host
  Write-Host ("{0} failed. Exit code: {1}" -f $Application.Name, $ExitCode) -ForegroundColor Red

  Write-DeploymentLog -Message ("{0} installation failed. Exit Code: {1}" -f $Application.Name, $ExitCode) -Level "ERROR"

  return [PSCustomObject]@{ Status = "Failed"; Message = ("{0} installation failed. Exit code: {1}" -f $Application.Name, $ExitCode) }
}

function Uninstall-ApplicationWithWinget {
  param ([PSCustomObject]$Application)

  Write-Host
  Write-Host "Uninstalling $($Application.Name)..." -ForegroundColor Cyan

  try {
    $WingetArguments = Get-WingetUninstallArguments -Application $Application
  }

  catch {
    Write-Host
    Write-Host $_.Exception.Message -ForegroundColor Red

    Write-DeploymentLog -Message $_.Exception.Message -Level "ERROR"

    return [PSCustomObject]@{ Status = "Failed"; Message = $_.Exception.Message }
  }

  Write-DeploymentLog -Message ("Uninstallation started: {0} ({1})" -f $Application.Name, $Application.Winget)

  & winget @WingetArguments | Out-Host

  $ExitCode = $LASTEXITCODE

  if ($ExitCode -eq 0) {
    Write-Host
    Write-Host ("$($Application.Name) uninstalled successfully.") -ForegroundColor Green

    Write-DeploymentLog -Message "$($Application.Name) uninstalled successfully." -Level "SUCCESS"

    return [PSCustomObject]@{ Status = "Uninstalled"; Message = "$($Application.Name) uninstalled successfully." }
  }

  Write-Host
  Write-Host ("{0} failed. Exit code: {1}" -f $Application.Name, $ExitCode) -ForegroundColor Red

  Write-DeploymentLog -Message ("{0} uninstallation failed. Exit Code: {1}" -f $Application.Name, $ExitCode) -Level "ERROR"

  return [PSCustomObject]@{ Status = "Failed"; Message = ("{0} uninstallation failed. Exit code: {1}" -f $Application.Name, $ExitCode) }
}