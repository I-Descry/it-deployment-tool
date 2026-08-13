# ============================================================
# SCRIPT INSTALLER
# ============================================================

function Get-ScriptInstallerPath {
  param(
    [Parameter(Mandatory)]
    [PSCustomObject]$Application
  )

  return Get-OfflineInstallerPath -Application $Application
}

function Test-ScriptInstallerFile {
  param(
    [Parameter(Mandatory)]
    [PSCustomObject]$Application
  )

  $InstallerPath = Get-ScriptInstallerPath -Application $Application

  if ([string]::IsNullOrWhiteSpace([string]$InstallerPath)) {
      return $false
  }

  if (-not (Test-Path -LiteralPath $InstallerPath -PathType Leaf)) {
      return $false
  }

  $Extension = [System.IO.Path]::GetExtension($InstallerPath).ToLowerInvariant()

  if ($Extension -notin @(
      ".ps1"
      ".bat"
      ".cmd"
  )) {
      return $false
  }

  return $true
}

function Get-ScriptInstallerType {
  param(
    [Parameter(Mandatory)]
    [PSCustomObject]$Application
  )

  $InstallerPath = Get-ScriptInstallerPath -Application $Application

  $Extension = ([System.IO.Path]::GetExtension($InstallerPath)).ToLowerInvariant()

  switch ($Extension) {
    ".ps1" {
      return "PowerShell"
    }

    ".bat" {
      return "Batch"
    }

    ".cmd" {
      return "Command"
    }

    default {
      return $null
    }
  }
}

function Install-ApplicationWithScript {
  param(
    [Parameter(Mandatory)]
    [PSCustomObject]$Application
  )

  $InstallerPath = Get-ScriptInstallerPath -Application $Application

  if (-not (Test-ScriptInstallerFile -Application $Application)) {
    Write-Host
    Write-Host ("{0} script installer was not found or is invalid." -f $Application.Name) -ForegroundColor Red

    Write-DeploymentLog -Message ("{0} script installer was not found or is invalid." -f $Application.Name) -Level "ERROR"

    return $false
  }

  $ScriptType = Get-ScriptInstallerType -Application $Application

  if ($ScriptType -eq "PowerShell") {
    $FilePath = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
    $ArgumentList = '-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $InstallerPath
  }

  else {
    $FilePath = $InstallerPath
    $ArgumentList = $null
  }

  Write-Host
  Write-Host ("Installing {0}..." -f $Application.Name) -ForegroundColor Cyan

  Write-DeploymentLog -Message ("Script installation started: {0}" -f $Application.Name)

  $ProcessParameters = @{
    FilePath         = $FilePath
    WorkingDirectory = Split-Path $InstallerPath -Parent
    Wait             = $true
    PassThru         = $true
    ErrorAction      = "Stop"
  }

  if (-not [string]::IsNullOrWhiteSpace($ArgumentList)) {
    $ProcessParameters["ArgumentList"] = $ArgumentList
  }

  try {
    $Process = Start-Process @ProcessParameters
    $ExitCode = $Process.ExitCode

    $InstallSucceeded = Test-ApplicationSuccessExitCode -Application $Application -ExitCode $ExitCode
    $RestartRecommended = Test-ApplicationRebootExitCode -Application $Application -ExitCode $ExitCode

    if ($InstallSucceeded) {
      Write-Host
      Write-Host ("{0} installed successfully." -f $Application.Name) -ForegroundColor Green

      Write-DeploymentLog -Message ("{0} installed successfully." -f $Application.Name) -Level "SUCCESS"

      if ($RestartRecommended) {
        Write-Host ("Restart recommended to complete {0} setup." -f $Application.Name) -ForegroundColor Yellow

        Write-DeploymentLog -Message ("{0} installed successfully. Restart recommended. Exit code: {1}" -f $Application.Name, $ExitCode) -Level "WARNING"
      }

      return $true
    }

    Write-Host
    Write-Host ("{0} failed. Exit code: {1}" -f $Application.Name, $ExitCode) -ForegroundColor Red

    Write-DeploymentLog -Message ("{0} script installation failed. Exit code: {1}" -f $Application.Name, $ExitCode) -Level "ERROR"

    return $false
  }

  catch {
    Write-Host
    Write-Host ("{0} script installer failed to start: {1}" -f $Application.Name, $_.Exception.Message) -ForegroundColor Red

    Write-DeploymentLog -Message ("{0} script installer failed to start: {1}" -f $Application.Name, $_.Exception.Message) -Level "ERROR"

    return $false
  }
}