# ============================================================
# IT Deployment Tool
# Version 1.1.0-dev
# Author : IT04 - John Paul Villacorta
# ============================================================

# ============================================================
# Application Information
# ============================================================

[CmdletBinding()]
param(
  [switch]$ValidateOnly,
  [switch]$Gui
)

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
  "Installation\UninstallationResult.ps1"
  "Installation\InstallerDirectories.ps1"
  "Installation\WingetInstaller.ps1"
  "Installation\OfflineInstaller.ps1"
  "Installation\MsiInstaller.ps1"
  "Installation\AppxInstaller.ps1"
  "Installation\ScriptInstaller.ps1"
  "Installation\ZipInstaller.ps1"
  "Installation\CrowdStrikeInstaller.ps1"
  "Installation\OfficeIsoInstaller.ps1"
  "Installation\Office2021ImgInstaller.ps1"
  "Installation\InstallationRouter.ps1"
  "Installation\UninstallationRouter.ps1"
  "Installation\InstallationQueue.ps1"
  "Installation\UninstallationQueue.ps1"

  "Windows\ComputerNameConfiguration.ps1"
  "Windows\LocalUserConfiguration.ps1"
  "Windows\PowerConfiguration.ps1"
  "Windows\WindowsConfiguration.ps1"
  "Windows\LenovoAssetId.ps1"

  "Validation\DeploymentValidation.ps1"
  "Validation\InstallerPackageReadiness.ps1"

  "Gui\GuiDialog.ps1"
  "Gui\GuiIcons.ps1"
  "Gui\GuiDeploymentValidationScreen.ps1"
  "Gui\GuiApplicationsScreen.ps1"
  "Gui\GuiDeploymentLogsScreen.ps1"
  "Gui\GuiWindowsConfigScreen.ps1"
  "Gui\GuiWindow.ps1"

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
    "Show-GuiDialog"
    "Get-DeploymentAssetIdFields"
    "Set-DeploymentAssetIdFields"
    "Invoke-DeploymentAssetIdWrite"
    "Start-Application"
    "Install-SelectedApplications"
    "Install-ApplicationByType"
    "New-ApplicationInstallationResult"
    "ConvertTo-ApplicationInstallationResult"
    "Uninstall-ApplicationByType"
    "Uninstall-SelectedApplications"
    "New-ApplicationUninstallationResult"
    "ConvertTo-ApplicationUninstallationResult"
    "Initialize-InstallerDirectories"
    "Get-InstallerPackageReadiness"
    "Show-InstallerPackageReadiness"
    "Test-MsiInstallerFile"
    "Get-MsiInstallerArguments"
    "Install-ApplicationWithMsi"
    "Test-ScriptInstallerFile"
    "Get-ScriptInstallerType"
    "Install-ApplicationWithScript"
    "Get-ZipPackagePath"
    "Test-ZipDeploymentPackage"
    "Expand-ZipDeploymentPackage"
    "Remove-ZipDeploymentExtraction"
    "Install-ApplicationFromZip"
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

  if ($ModulePaths.Count -ne 47) {
    $ValidationProblems += ("Expected 45 modules but the loader contains {0}." -f $ModulePaths.Count)
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

$AdministratorGranted = Request-Administrator -ScriptPath $PSCommandPath -Gui:$Gui

if (-not $AdministratorGranted) {
  exit
}

if ($Gui) {
  # GUI mode is meant to look and feel like a normal Windows application, not
  # a script running in a console. The console window still exists (WPF has
  # no windowless PowerShell host), so it is hidden rather than left visible
  # behind/alongside the GUI window.
  Add-Type -Name Win32ConsoleWindow -Namespace ITDeploymentTool -MemberDefinition '
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
  '

  $ConsoleWindowHandle = [ITDeploymentTool.Win32ConsoleWindow]::GetConsoleWindow()

  if ($ConsoleWindowHandle -ne [IntPtr]::Zero) {
    [ITDeploymentTool.Win32ConsoleWindow]::ShowWindow($ConsoleWindowHandle, 0) | Out-Null
  }

  Show-MainWindow
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