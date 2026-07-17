# ============================================================
# OFFLINE INSTALLER
# ============================================================

function Get-OfflineInstallerPath {
  param(
    [PSCustomObject]$Application
  )

  $InstallersDirectory = Join-Path $PSScriptRoot "..\Installers"

  return Join-Path $InstallersDirectory $Application.InstallerPath
}

function Test-OfflineInstallerFile {
  param(
    [PSCustomObject]$Application
  )

  $InstallerPath = Get-OfflineInstallerPath -Application $Application
  
  return Test-Path -LiteralPath $InstallerPath -PathType Leaf
}

function Install-ApplicationWithExe {
  param(
    [PSCustomObject]$Application
  )

  $InstallerPath = Get-OfflineInstallerPath -Application $Application

  if (-not (Test-OfflineInstallerFile -Application $Application)) {
    Write-Host
    Write-Host ("$($Application.Name) installer file was not found.") -ForegroundColor Red

    Write-DeploymentLog -Message "$($Application.Name) EXE installer was not found." -Level "ERROR"

    return $false
  }

  if ([System.IO.Path]::GetExtension($InstallerPath) -ne ".exe") {
    Write-Host
    Write-Host ("$($Application.Name) does not use a valid EXE installer.") -ForegroundColor Red

    Write-DeploymentLog -Message "$($Application.Name) has an invalid EXE installer." -Level "ERROR"

    return $false
  }

  Write-Host
  Write-Host "Installing $($Application.Name)..." -ForegroundColor Cyan

  Write-DeploymentLog -Message ("Offline EXE installation started: {0}" -f $Application.Name)

  $ProcessParameters = @{
    FilePath         = $InstallerPath
    WorkingDirectory = Split-Path $InstallerPath -Parent
    Wait             = $true
    PassThru         = $true
    ErrorAction      = "Stop"
  }

  $SilentArguments = [string]$Application.$SilentArguments
  
  if (-not [string]::IsNullOrWhiteSpace($SilentArguments)) {
    $ProcessParameters.ArgumentList = $SilentArguments
  }

  try {
    $Process = Start-Process @ProcessParameters
    $ExitCode = $Process.ExitCode

    if ($ExitCode -eq 0) {
      Write-Host
      Write-Host ("$($Application.Name) installed successfully.") -ForegroundColor Green

      Write-DeploymentLog -Message "$($Application.Name) installed successfully." -Level "SUCCESS"

      return $true
    }

    Write-Host
    Write-Host ("$($Application.Name) failed. Exit code: {0}" -f $ExitCode) -ForegroundColor Red

    Write-DeploymentLog -Message ("{0} EXE installation failed. Exit code: {1}" -f $Application.Name, $ExitCode) -Level "ERROR"

    return $false
  }

  catch {
    Write-Host
    Write-Host ("$($Application.Name) failed to start: {0}" -f $_.Exception.Message) -ForegroundColor Red

    Write-DeploymentLog -Message ("{0} EXE installer failed to start: {1}" -f $Application.Name, $_.Exception.Message) -Level "ERROR"

    return $false
  }
}