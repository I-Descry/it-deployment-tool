# ============================================================
# MSI INSTALLER
# ============================================================

function Get-MsiInstallerPath {
  param(
    [Parameter(Mandatory)]
    [PSCustomObject]$Application
  )

  return Get-OfflineInstallerPath -Application $Application
}

function Test-MsiInstallerFile {
  param(
    [Parameter(Mandatory)]
    [PSCustomObject]$Application
  )

  $InstallerPath = Get-MsiInstallerPath -Application $Application

  if (-not (Test-Path -LiteralPath $InstallerPath -PathType Leaf)) {
    return $false
  }

  $Extension = [System.IO.Path]::GetExtension($InstallerPath)

  return $Extension.Equals(".msi", [System.StringComparison]::OrdinalIgnoreCase)
}

function Get-MsiInstallerArguments {
  param(
    [Parameter(Mandatory)]
    [PSCustomObject]$Application,

    [Parameter(Mandatory)]
    [string]$InstallerPath
  )

  $SilentArguments = [string]$Application.$SilentArguments

  if ([string]::IsNullOrWhiteSpace($SilentArguments)) {
    $SilentArguments = "/qn /norestart"
  }

  return ('/i "{0}" {1}' -f $InstallerPath, $SilentArguments).Trim()
}

function Install-ApplicationWithMsi {
  param(
    [Parameter(Mandatory)]
    [PSCustomObject]$Application
  )

  $InstallerPath = Get-MsiInstallerPath -Application $Application

  if (-not (Test-MsiInstallerFile -Application $Application)) {
    Write-Host
    Write-Host ("{0} MSI installer was not found or is invalid." -f $Application.Name) -ForegroundColor Red

    Write-DeploymentLog -Message ("{0} MSI installer was not found or is invalid." -f $Application.Name) -Level "ERROR"

    return $false
  }

  $MsiExecPath = Join-Path $env:SystemRoot "System32\msiexec.exe"

  if (-not (Test-Path -LiteralPath $MsiExecPath -PathType Leaf)) {
    Write-Host
    Write-Host "Windows Installer could not be found." -ForegroundColor Red

    Write-DeploymentLog -Message "Windows Installer executable could not be found." -Level "ERROR"

    return $false
  }

  $Arguments = Get-MsiInstallerArguments -Application $Application -InstallerPath $InstallerPath

  Write-Host
  Write-Host ("Installing {0}..." -f $Application.Name) -ForegroundColor Cyan
  
  Write-DeploymentLog -Message ("MSI installation started: {0}" -f $Application.Name)

  $ProcessParameters = @{
    FilePath         = $MsiExecPath
    ArgumentList     = $Arguments
    WorkingDirectory = Split-Path $InstallerPath -Parent
    Wait             = $true
    PassThru         = $true
    ErrorAction      = "Stop"
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

    Write-DeploymentLog -Message ("{0} MSI installation failed. Exit code: {1}" -f $Application.Name, $ExitCode) -Level "ERROR"

    return $false
  }

  catch {
    Write-Host
    Write-Host ("{0} MSI installer failed to start: {1}" -f $Application.Name, $_.Exception.Message) -ForegroundColor Red

    Write-DeploymentLog -Message ("{0} MSI installer failed to start: [1]" -f $Application.Name, $_.Exception.Message) -Level "ERROR"

    return $false
  }
}

function Get-MsiUninstallerArguments {
  param(
    [Parameter(Mandatory)]
    [string]$InstallerPath
  )

  return ('/x "{0}" /qn /norestart' -f $InstallerPath)
}

function Uninstall-ApplicationWithMsi {
  param(
    [Parameter(Mandatory)]
    [PSCustomObject]$Application
  )

  $InstallerPath = Get-MsiInstallerPath -Application $Application

  if (-not (Test-MsiInstallerFile -Application $Application)) {
    Write-Host
    Write-Host ("{0} MSI installer was not found or is invalid." -f $Application.Name) -ForegroundColor Red

    Write-DeploymentLog -Message ("{0} MSI installer was not found or is invalid." -f $Application.Name) -Level "ERROR"

    return $false
  }

  $MsiExecPath = Join-Path $env:SystemRoot "System32\msiexec.exe"

  if (-not (Test-Path -LiteralPath $MsiExecPath -PathType Leaf)) {
    Write-Host
    Write-Host "Windows Installer could not be found." -ForegroundColor Red

    Write-DeploymentLog -Message "Windows Installer executable could not be found." -Level "ERROR"

    return $false
  }

  $Arguments = Get-MsiUninstallerArguments -InstallerPath $InstallerPath

  Write-Host
  Write-Host ("Uninstalling {0}..." -f $Application.Name) -ForegroundColor Cyan

  Write-DeploymentLog -Message ("MSI uninstallation started: {0}" -f $Application.Name)

  $ProcessParameters = @{
    FilePath         = $MsiExecPath
    ArgumentList     = $Arguments
    WorkingDirectory = Split-Path $InstallerPath -Parent
    Wait             = $true
    PassThru         = $true
    ErrorAction      = "Stop"
  }

  try {
    $Process = Start-Process @ProcessParameters
    $ExitCode = $Process.ExitCode

    if ($ExitCode -eq 0) {
      Write-Host
      Write-Host ("{0} uninstalled successfully." -f $Application.Name) -ForegroundColor Green

      Write-DeploymentLog -Message ("{0} uninstalled successfully." -f $Application.Name) -Level "SUCCESS"

      return $true
    }

    Write-Host
    Write-Host ("{0} failed. Exit code: {1}" -f $Application.Name, $ExitCode) -ForegroundColor Red

    Write-DeploymentLog -Message ("{0} MSI uninstallation failed. Exit code: {1}" -f $Application.Name, $ExitCode) -Level "ERROR"

    return $false
  }

  catch {
    Write-Host
    Write-Host ("{0} MSI uninstaller failed to start: {1}" -f $Application.Name, $_.Exception.Message) -ForegroundColor Red

    Write-DeploymentLog -Message ("{0} MSI uninstaller failed to start: {1}" -f $Application.Name, $_.Exception.Message) -Level "ERROR"

    return $false
  }
}
