# ============================================================
# WINGET INSTALLER
# ============================================================

function Get-WingetSource {
  param(
    [PSCustomObject]$Application
  )

  $ConfiguredSource = [string]$Application.WingetSource

  if ([string]::IsNullOrWhiteSpace($ConfiguredSource)) {
    return "winget"
  }

  return $ConfiguredSource.Trim().ToLowerInvariant()
}

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
    (Get-WingetSource -Application $Application)
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
    (Get-WingetSource -Application $Application)
    "--silent"
    "--accept-source-agreements"
    "--disable-interactivity"
  )

  $WingetArguments += @(Get-WingetScopeArguments -Application $Application)

  return $WingetArguments
}

# WinGet exit code -1978335217 (0x8A15000F, "Data required by the source is missing") is a known, confirmed-real WinGet/AppX bug where an elevated process cannot read the Microsoft.Winget.Source package's data even though the same command works fine unelevated; re-registering that package from its existing files is the confirmed real-device fix.
$script:WingetSourceDataMissingExitCode = -1978335217

function Repair-WingetSourceDataPackage {
  # Re-registers the Microsoft.Winget.Source AppX package from its existing files, without reinstalling or removing anything, to recover from the known source-data-missing exit code.
  try {
    $SourcePackage = Get-AppxPackage -AllUsers "Microsoft.Winget.Source" -ErrorAction Stop | Select-Object -First 1

    if ($null -eq $SourcePackage) {
      return $false
    }

    $ManifestPath = Join-Path $SourcePackage.InstallLocation "AppXManifest.xml"

    Add-AppxPackage -DisableDevelopmentMode -Register $ManifestPath -ErrorAction Stop

    return $true
  }

  catch {
    return $false
  }
}

function Invoke-WingetCommandWithSourceRepair {
  # Runs a winget command and, if it fails with the known source-data-missing exit code, attempts the confirmed repair once and retries the same command once before giving up.
  param(
    [Parameter(Mandatory)]
    [string[]]$WingetArguments,

    [Parameter(Mandatory)]
    [string]$ApplicationName
  )

  & winget @WingetArguments | Out-Host

  $ExitCode = $LASTEXITCODE

  if ($ExitCode -eq $script:WingetSourceDataMissingExitCode) {
    Write-Host
    Write-Host "Detected a known WinGet source issue -- attempting an automatic repair and retry..." -ForegroundColor Yellow

    Write-DeploymentLog -Message ("WinGet returned the known source-data-missing exit code ({0}) for {1}; attempting automatic repair and one retry." -f $ExitCode, $ApplicationName) -Level "WARNING"

    if (Repair-WingetSourceDataPackage) {
      & winget @WingetArguments | Out-Host

      $ExitCode = $LASTEXITCODE
    }
  }

  return $ExitCode
}

function Test-WingetPackage {
  # Only confirms winget itself is present, not that this specific package ID exists -- "winget show" was found to give false negatives on a real device where winget's source data was unreadable from this tool's elevated process even though "winget install" for that same package succeeded fine. Install-ApplicationWithWinget's own exit-code handling is the real, reliable source of truth for whether a specific package installs.
  param([PSCustomObject]$Application)

  $WingetCommand = Get-Command -Name "winget" -ErrorAction SilentlyContinue

  return ($null -ne $WingetCommand)
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

  $ExitCode = Invoke-WingetCommandWithSourceRepair -WingetArguments $WingetArguments -ApplicationName $Application.Name

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

  $ExitCode = Invoke-WingetCommandWithSourceRepair -WingetArguments $WingetArguments -ApplicationName $Application.Name

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