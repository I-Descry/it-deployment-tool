# ============================================================
# IT Deployment Tool
# Version 1.1.0-dev
# Author : IT04 - John Paul Villacorta
# ============================================================

# ============================================================
# Application Information
# ============================================================

[CmdletBinding()]
param([switch]$ValidateOnly)

$AppName = "IT DEPLOYMENT TOOL"
$AppVersion = "1.1.0-dev"
$AppAuthor = "IT04 - John Paul Villacorta"
$script:ITDeploymentToolRoot = $PSScriptRoot

# ============================================================
# System Information
# ============================================================

$SystemInfo = [PSCustomObject]@{

    ComputerName    = $null
    LoggedUser      = $null

    Manufacturer    = $null
    Model           = $null
    SerialNumber    = $null

    WindowsEdition  = $null

    IsAdministrator = $false
    InternetStatus  = $false
    WingetAvailable = $false

}

# ============================================================
# Load Modules
# ============================================================

$ModulePaths = @(
  "Core\Elevation.ps1"
  "Core\Logging.ps1"
  "Core\UI.ps1"

  "Validation\SystemInformation.ps1"
  "Validation\SystemChecks.ps1"

  "Applications\ApplicationCatalog.ps1"
  "Applications\ApplicationSelection.ps1"
  "Applications\InstalledApplications.ps1"
  "Applications\ApplicationProcessCheck.ps1"
  "Applications\MicrosoftTeams.ps1"

  "Installation\InstallationResult.ps1"
  "Installation\InstallerDirectories.ps1"
  "Installation\WingetInstaller.ps1"
  "Installation\OfflineInstaller.ps1"
  "Installation\MsiInstaller.ps1"
  "Installation\CrowdStrikeInstaller.ps1"
  "Installation\OfficeIsoInstaller.ps1"
  "Installation\Office2021ImgInstaller.ps1"
  "Installation\InstallationRouter.ps1"
  "Installation\InstallationQueue.ps1"

  "Windows\ComputerNameConfiguration.ps1"
  "Windows\LocalUserConfiguration.ps1"
  "Windows\PowerConfiguration.ps1"
  "Windows\WindowsConfiguration.ps1"

  "Validation\DeploymentValidation.ps1"
  "Validation\InstallerPackageReadiness.ps1"

  "Interface\DeploymentLogs.ps1"
  "Interface\DeploymentLogsMenu.ps1"
  "Interface\SelectedApplicationsSetup.ps1"
  "Interface\ApplicationMenu.ps1"
  "Interface\WindowsConfigurationMenu.ps1"
  "Interface\Menu.ps1"
  "Interface\Application.ps1"
)

foreach ($ModulePath in $ModulePaths) {
  $FullModulePath = Join-Path $script:ITDeploymentToolRoot "Modules\$ModulePath"

  if (-not (Test-Path -LiteralPath $FullModulePath -PathType Leaf)) {
    throw "Required module was not found: $ModulePath"
  }

  . $FullModulePath
}

if ($ValidateOnly) {
  $RequiredFunctions = @(
    "Request-Administrator"
    "Start-Application"
    "Install-SelectedApplications"
    "Install-ApplicationByType"
    "New-ApplicationInstallationResult"
    "ConvertTo-ApplicationInstallationResult"
    "Initialize-InstallerDirectories"
    "Get-InstallerPackageReadiness"
    "Show-InstallerPackageReadiness"
    "Test-MsiInstallerFile"
    "Get-MsiInstallerArguments"
    "Install-ApplicationWithMsi"
  )

  $MissingFunctions = @(
    foreach ($FunctionName in $RequiredFunctions) {
      if (-not (Get-Command -Name $FunctionName -CommandType Function -ErrorAction SilentlyContinue)) {
        $FunctionName
      }
    }
  )

  $ApplicationConfigPath = Join-Path $script:ITDeploymentToolRoot "Config\Applications.json"

  $ValidationProblems = @()

  if ($ModulePaths.Count -ne 33) {
    $ValidationProblems += ("Expected 33 modules but the loader contains {0}." -f $ModulePaths.Count)
  }

  if ($MissingFunctions.Count -gt 0) {
    $ValidationProblems += ("Missing functions: {0}" -f ($MissingFunctions -join ", "))
  }

  if (-not (Test-Path -LiteralPath $ApplicationConfigPath -PathType Leaf)) {
    $ValidationProblems += ("Application configuration was not found: {0}" -f $ApplicationConfigPath)
  }

  if ($ValidationProblems.Count -gt 0) {
    Write-Host
    Write-Host "Deployment tool validation failed." -ForegroundColor Red

    foreach ($Problem in $ValidationProblems) {
      Write-Host ("- {0}" -f $Problem) -ForegroundColor Red
    }

    exit 1
  }

  Write-Host
  Write-Host "Deployment tool validation passed." -ForegroundColor Green
  Write-Host ("Modules loaded    : {0}" -f $ModulePaths.Count)
  Write-Host ("Functions checked : {0}" -f $RequiredFunctions.Count)
  Write-Host "Configuration     : Available"

  exit 0
}

$AdministratorGranted = Request-Administrator -ScriptPath $PSCommandPath

if (-not $AdministratorGranted) {
  exit
}

# ============================================================
# Initialize Installer Directories
# ============================================================

try {
  [void](Initialize-InstallerDirectories)
}

catch {
  Write-Host
  Write-Host "Installer directory initialization failed." -ForegroundColor Red
  Write-Host $_.Exception.Message -ForegroundColor Red
  exit 1
}

# ============================================================
# Application Starts Here
# ============================================================

Start-Application