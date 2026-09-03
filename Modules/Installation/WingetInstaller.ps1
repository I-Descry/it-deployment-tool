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

function Repair-AppxPackageRegistration {
  # Re-registers an already-installed AppX package from its existing files for the current user session, without reinstalling or removing anything. Shared by Repair-WingetSourceDataPackage (a known source-data-missing exit code) and Test-WingetAvailable (winget.exe itself not registered/active for the current session).
  param(
    [Parameter(Mandatory)]
    [string]$PackageName
  )

  try {
    $Package = Get-AppxPackage -AllUsers $PackageName -ErrorAction Stop | Select-Object -First 1

    if ($null -eq $Package) {
      return $false
    }

    $ManifestPath = Join-Path $Package.InstallLocation "AppXManifest.xml"

    Add-AppxPackage -DisableDevelopmentMode -Register $ManifestPath -ErrorAction Stop

    return $true
  }

  catch {
    return $false
  }
}

function Repair-WingetSourceDataPackage {
  # Thin wrapper over Repair-AppxPackageRegistration, kept for its existing name and call sites -- recovers from the known source-data-missing exit code.
  return Repair-AppxPackageRegistration -PackageName "Microsoft.Winget.Source"
}

function Test-WingetAvailable {
  # Get-Command only ever resolves winget.exe for the CURRENT process's own account. When elevation switched to a different account than the real interactively logged-on user (e.g. the Built-in Administrator, required when the real user is a standard, non-admin account), winget's own per-user app execution alias is genuinely not registered/active for THIS account -- even on a device where Microsoft.DesktopAppInstaller is installed machine-wide and the real user's own session has winget working fine. Detects that specific case (the package is installed, just not registered for this session) and re-registers it, the same repair Repair-WingetSourceDataPackage already uses for a different known WinGet bug, before concluding winget is genuinely unavailable. Checks the well-known alias path directly afterward rather than re-calling Get-Command, since PowerShell's own command-resolution cache is not guaranteed to immediately notice a file that only just started existing.
  if ($null -ne (Get-Command -Name "winget.exe" -ErrorAction SilentlyContinue)) {
    return $true
  }

  $DesktopAppInstallerPackage = Get-AppxPackage -AllUsers "Microsoft.DesktopAppInstaller" -ErrorAction SilentlyContinue | Select-Object -First 1

  if ($null -eq $DesktopAppInstallerPackage) {
    return $false
  }

  if (-not (Repair-AppxPackageRegistration -PackageName "Microsoft.DesktopAppInstaller")) {
    return $false
  }

  $AliasPath = Join-Path $env:LOCALAPPDATA "Microsoft\WindowsApps\winget.exe"

  return (Test-Path -LiteralPath $AliasPath -PathType Leaf)
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

  return Test-WingetAvailable
}

function Install-ApplicationWithWinget {
  param([PSCustomObject]$Application)

  Write-Host
  Write-Host "Installing $($Application.Name)..." -ForegroundColor Cyan

  try {
    $WingetArguments = Get-WingetInstallArguments -Application $Application

    if (-not (Test-WingetAvailable)) {
      throw "WinGet is not available in this session."
    }
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

    if (-not (Test-WingetAvailable)) {
      throw "WinGet is not available in this session."
    }
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