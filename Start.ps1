# ============================================================
# IT Deployment Tool
# Version 1.1.0-dev
# Author : IT04 - John Paul Villacorta
# ============================================================

# ============================================================
# Application Information
# ============================================================

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
  "Installation\WingetInstaller.ps1"
  "Installation\OfflineInstaller.ps1"
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

$AdministratorGranted = Request-Administrator -ScriptPath $PSCommandPath

if (-not $AdministratorGranted) {
  exit
}

# ============================================================
# Application Starts Here
# ============================================================

Start-Application