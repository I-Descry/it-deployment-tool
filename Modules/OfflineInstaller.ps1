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

function Test-ApplicationSuccessExitCode {
  param(
    [PSCustomObject]$Application,
    [int]$ExitCode
  )

  $SuccessExitCodes = @($Application.SuccessExitCodes)

  if ($SuccessExitCodes.Count -eq 0) {
    $SuccessExitCodes = @(0)
  }

  $SuccessExitCodes = @(
    $SuccessExitCodes | ForEach-Object {
      [int]$_
    }
  )

  return ($ExitCode -in $SuccessExitCodes)
}

function Test-ApplicationRebootExitCode {
  param(
    [PSCustomObject]$Application,
    [int]$ExitCode
  )

  $RebootExitCodes = @($Application.RebootExitCodes | Where-Object { $null -ne $_ })

  return ($RebootExitCodes -contains $ExitCode)
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

    $InstallSucceeded = Test-ApplicationSuccessExitCode -Application $Application -ExitCode $ExitCode

    $RestartRecommended = Test-ApplicationRebootExitCode -Application $Application -ExitCode $ExitCode

    if ($InstallSucceeded) {
      Write-Host
      Write-Host ("$($Application.Name) installed successfully.") -ForegroundColor Green

      Write-DeploymentLog -Message "$($Application.Name) installed successfully." -Level "SUCCESS"

      if ($RestartRecommended) {
        Write-Host ("Restart recommended to complete $($Application.Name) setup.") -ForegroundColor Yellow

        Write-DeploymentLog -Message ("{0} installed successfully. Restart recommended. Exit code: {1}" -f $Application.Name, $ExitCode) -Level "WARNING"
      }

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