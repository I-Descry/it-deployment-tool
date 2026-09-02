# IT Deployment Tool

A modular PowerShell-based deployment tool designed to automate application installation and simplify the setup of new Windows devices.

Instead of manually downloading and installing applications one at a time, the tool provides a single interactive interface for selecting and processing multiple applications. It reduces repetitive work, saves deployment time, minimizes manual errors, and helps maintain a consistent device setup process.

---

## Current Version

`1.1.0-dev`

This development version adds CrowdStrike deployment, Microsoft Office 2024 and Office 2021 LOP installation, Windows device configuration, deployment validation, application conflict protection, and required-application validation.

Local non-destructive acceptance testing has been completed. Fresh application installations and real system changes remain pending because an authorized clean test device is not currently available.

The version will remain `1.1.0-dev` until the remaining acceptance tests pass.

---

## Features

### System Information and Requirements

- Displays the computer name, logged-in user, manufacturer, and model
- Checks whether the tool is running with administrator privileges
- Automatically requests administrator elevation when required
- Checks internet connectivity
- Checks WinGet availability

### Application Management

- Loads applications from `Config/Applications.json`
- Groups applications by category
- Supports individual and multiple application selection
- Supports Select All, Select Recommended, and Clear All
- Tracks selections using interactive checkboxes
- Displays the installed status of each configured application
- Marks recommended applications
- Displays the total number of selected applications
- Previews manually selected applications before processing
- Requires confirmation before starting the installation queue
- Supports safe cancellation

### Installation Automation

- Detects installed applications through the Windows Registry
- Detects CrowdStrike through the `CSFalconService` Windows service
- Skips applications that are already installed
- Checks installed status before checking installer availability
- Processes selected applications sequentially
- Supports silent installation through WinGet
- Supports local offline EXE installers
- Supports dedicated application-specific installation types
- Routes applications according to their configured installation type
- Validates offline installer files before execution
- Supports application-specific success exit codes
- Detects when an installer recommends a system restart
- Continues processing when an application is skipped or fails
- Displays a final installation summary
- Supports company applications such as SAP GUI and CrowdStrike Falcon Sensor
- Supports Microsoft Teams deployment using the official Teams bootstrapper
- Provisions Microsoft Teams for existing and future Windows users
- Validates the Microsoft digital signature before running the bootstrapper
- Supports optional browser deployment through WinGet:
  - Microsoft Edge
  - Brave Browser
  - Firefox Developer Edition
- Supports configurable WinGet installation scope:
  - Machine scope
  - User scope
- Supports exact WinGet detection for portable applications
- Supports optional deployment of:
  - WinBox
  - Visual Studio Code
  - Git
- Checks configured blocking processes before launching an installer
- Prevents silent installers from failing when the target application is running
- Displays blocked applications separately in the installation summary
- Records blocked installation attempts as warnings in the deployment log
- Allows the technician to retry after closing a blocking application
- Allows the technician to skip a blocked application without stopping the remaining installation queue
- Does not automatically terminate running applications
- Normalizes installer results into `Installed`, `Skipped`, or `Failed`
- Counts cancelled or skipped interactive installers separately from successful installations
- Prevents skipped Office or CrowdStrike setup from being counted as installed
- Displays a status and reason for each application processed by the installation queue
- Distinguishes installed, skipped, blocked, failed, and missing-installer results
- Caches installed application registry data during each status refresh to avoid repeated registry scans

### Uninstallation Automation

- Uninstalls selected applications that are currently detected as installed
- Skips applications that are not currently installed
- Requires per-application confirmation before removing anything
- Supports silent uninstallation through WinGet
- Supports uninstallation of AppX/MSIX-packaged applications (including Microsoft Store apps such as WhatsApp) through `Remove-AppxPackage`
- Supports uninstallation of offline EXE applications using the registry `UninstallString`/`QuietUninstallString`
- Supports uninstallation of MSI applications using the original offline `.msi` package
- Supports uninstallation of ZIP-installed applications through the same registry-based path as EXE applications
- Supports uninstallation of Microsoft Teams, removing both the provisioned package and the current-user package
- Supports uninstallation of Script-type applications through a configurable `UninstallerPath`
- Supports uninstallation of Microsoft Office LTSC Standard 2024 by mounting the Office ISO and running the Office Deployment Tool with a local removal configuration file
- Supports uninstallation of Microsoft Office Professional Plus 2021 - LOP through the same registry-based path as EXE applications
- Returns a clear "not yet supported" result for installation types that do not yet support uninstallation
- Normalizes uninstallation results into `Uninstalled`, `Skipped`, or `Failed`
- Displays a final uninstallation summary
- Refreshes installed-application status after the uninstallation queue completes

### MSI Installer Support

The deployment tool supports Windows Installer packages using `msiexec.exe`.

MSI applications are configured with `InstallType` set to `MSI` and an installer path relative to the `Installers` directory.

Example:

```json
{
  "Name": "Example MSI Application",
  "DetectionName": "Example Application",
  "InstallType": "MSI",
  "InstallerPath": "MSI\\ExampleApp\\ExampleApp.msi",
  "SilentArguments": "/qn /norestart",
  "SuccessExitCodes": [0, 1641, 3010],
  "RebootExitCodes": [1641, 3010],
  "Category": "Company Applications",
  "Recommended": false
}
```

### Installer Package Organization

Offline installer packages are organized by primary package type:

- `Installers\EXE` - Executable-based installers
- `Installers\MSI` - Windows Installer packages
- `Installers\ISO` - ISO-based installation media
- `Installers\IMG` - IMG-based installation media
- `Installers\ZIP` - Archived deployment packages
- `Installers\Scripts` - Supporting deployment scripts

Application packages that contain multiple dependent files remain together inside their application folder.

### ZIP Package Support

ZIP deployment packages are supported through `InstallType: "ZIP"`.

ZIP applications must define:

- `InstallerPath` - ZIP package path relative to the `Installers` directory.
- `ExtractedInstallerPath` - path of the installer inside the ZIP archive.
- `ExtractedInstallType` - installer type inside the archive (`EXE` or `MSI`).
- `SilentArguments` - silent installation arguments passed to the extracted installer.

ZIP deployment performs the following workflow:

1. Validates the ZIP package.
2. Validates the configured internal installer path and type.
3. Rejects unsafe archive paths.
4. Extracts the package to a temporary deployment directory.
5. Passes the extracted EXE or MSI to the existing installer engine.
6. Preserves the original ZIP package.
7. Removes temporary extraction files after success or failure.

ZIP installation routing has been validated using mocked installer execution. A real ZIP deployment package remains pending authorized-device acceptance testing.

### Script Package Support

Script-based installer packages are supported through `InstallType: "Script"`.

Supported script types are detected automatically from the installer's file extension:

- `.ps1` - executed via `powershell.exe -NoProfile -ExecutionPolicy Bypass -File`
- `.bat` - executed directly through its registered Windows handler
- `.cmd` - executed directly through its registered Windows handler

Script applications are configured with an installer path relative to the `Installers` directory.

Example:

```json
{
  "Name": "Example Script Application",
  "InstallType": "Script",
  "InstallerPath": "Scripts\\ExampleApp\\Install.ps1",
  "SuccessExitCodes": [0],
  "RebootExitCodes": [3010],
  "Category": "Company Applications",
  "Recommended": false
}
```

Script deployment performs the following workflow:

1. Validates that the script file exists and has a supported extension.
2. Determines the script type from its file extension.
3. Runs the script using the appropriate host process for its type.
4. Evaluates the process exit code against configured `SuccessExitCodes` and `RebootExitCodes`.
5. Normalizes the result through the standard installation result system.

Script installation routing has been validated for success, failure, and reboot-recommended exit codes using local test scripts. A real script-based application package remains pending authorized-device acceptance testing.

### Automatic Installer Directory Initialization

During normal startup, the deployment tool automatically checks the required offline installer directory structure and creates any missing directories.

The following directories are maintained:

- `Installers\EXE`
- `Installers\EXE\CrowdStrike`
- `Installers\EXE\SAP`
- `Installers\MSI`
- `Installers\ISO`
- `Installers\ISO\Office2024`
- `Installers\IMG`
- `Installers\IMG\Office2021LOP`
- `Installers\ZIP`
- `Installers\Scripts`

Existing directories and installer files are left unchanged.

Directory initialization runs during normal deployment-tool startup. Validation mode does not create or modify installer directories.

### Installer Package Readiness Validation

The deployment tool can check whether required local installer packages are available before installation.

The readiness check supports:

- Offline EXE installers
- MSI installer packages
- CrowdStrike deployment packages
- Microsoft Office 2024 ISO packages
- Microsoft Office 2021 LOP IMG packages

The main menu provides an `Installer Package Status` option that displays each local package as `READY` or `MISSING`.

The readiness check is read-only and does not start any installation.

### Microsoft Teams

- Downloads the latest official Microsoft Teams bootstrapper
- Validates the bootstrapper's Microsoft digital signature
- Provisions Microsoft Teams for existing and future Windows users
- Detects the current-user `MSTeams` MSIX package
- Detects whether Microsoft Teams is provisioned on the device
- Skips deployment when Teams is already provisioned
- Removes the temporary bootstrapper after processing

Actual Microsoft Teams provisioning remains pending clean-device acceptance
testing.

### CrowdStrike Falcon Sensor

- Locates the CrowdStrike Windows Sensor installer automatically
- Reads the Customer ID and installation token from the local CrowdStrike package
- Validates the Customer ID format
- Does not display the actual Customer ID or token in the deployment interface
- Does not write the Customer ID or token to deployment logs
- Detects an existing installation using `CSFalconService`
- Skips installation when the sensor is already installed
- Opens the interactive CrowdStrike setup when installation is required
- Supplies the Customer ID and installation token to the installer
- Keeps acceptance of the Sensor Terms of Use as a manual technician action
- Verifies installation by checking for the Falcon service

The CrowdStrike installer and credential-containing README are excluded from Git.

### Microsoft Office 2024

- Uses a company-provided Office 2024 ISO installer
- Mounts the ISO automatically without opening it manually
- Copies the installation files to a temporary local directory
- Removes Windows downloaded-file security blocks from the copied files
- Runs the authorized `Easy Install.bat` file from an elevated deployment session
- Waits for the Office installation process to complete
- Verifies whether Microsoft Office was installed successfully
- Dismounts the ISO and removes temporary installation files after processing

#### Office Activation Notice

Microsoft Office product activation is currently performed manually after installation.

The existing product keys have limited remaining activation availability, so they will not be stored in or automatically applied by the deployment tool. After the remaining authorized activations have been used and new company-approved product keys are provided, secure activation automation may be added in a future version.

Until then, the technician must activate Office manually from an Office application such as Excel:

```text
Excel > File > Account > Change Product Key
```

### Microsoft Office Professional Plus 2021 — LOP

The deployment tool supports installing Microsoft Office Professional Plus 2021 Retail on authorized LOP laptops from a local disc image.

Installation workflow:

1. Locate `ProPlus2021Retail.img`.
2. Confirm the image is available.
3. Block installation when another Click-to-Run Office edition is installed.
4. Mount the disc image.
5. Verify that `Setup.exe` has a valid Microsoft digital signature.
6. Run `Setup.exe /AUTORUN`.
7. Wait for setup to complete.
8. Verify that `ProPlus2021Retail` is installed.
9. Dismount the disc image.

Office activation remains manual and is not performed, stored, or logged by
the deployment tool.

Installer location:

```text
Installers\Office2021LOP\ProPlus2021Retail.img
```

### Application Conflict Validation

Before starting the installation queue, the deployment tool checks the selected applications for incompatible combinations.

Currently, the tool prevents these Office editions from being selected together:

- Microsoft Office LTSC Standard 2024
- Microsoft Office Professional Plus 2021 — LOP

When a conflict is detected:

- The selected applications preview is not opened.
- The installation queue does not start.
- No Office installer is mounted or executed.
- A warning is written to the deployment log.
- The technician must select only one Office edition.

This validation prevents conflicting Office editions from being processed during the same deployment operation.

---

### Windows Configuration

The IT Deployment Tool includes a Windows Configuration menu for common device-preparation tasks.

```text
Configure Windows
├── Rename Computer
├── Create Local Standard User
├── Configure Power and Sleep Settings
└── View Current Windows Configuration
```

#### View Current Windows Configuration

Displays read-only information about the current Windows device:

- Computer name
- Manufacturer and model
- Serial number
- Domain or workgroup
- Windows edition, version, build, and architecture
- Logged-in user
- Administrator status
- Active power plan
- Plugged-in sleep timeout
- Battery sleep timeout

This feature does not modify the device.

#### Rename Computer

Allows the technician to rename the computer using the company naming standard:

```text
POSITION-NAME
```

Example:

```text
IT04-JP
```

Validation and safety features:

- Maximum of 15 characters
- Letters and numbers are allowed
- One hyphen is required
- Names are converted to uppercase
- Invalid names are rejected
- Administrator permission is required
- The computer is not restarted automatically

A Windows restart is required before the new computer name is fully applied.

#### Create Local Standard User

Creates a local Windows account configured as a standard user.

Security and validation features:

- Secure password input
- Password confirmation
- Passwords are not displayed, stored, or logged
- Existing usernames are rejected
- Reserved Windows usernames are rejected
- Invalid username characters are rejected
- The account is added to the built-in Users group
- The account is verified not to belong to Administrators
- Incomplete accounts are removed when configuration fails
- Administrator permission is required

Supported username characters:

```text
Letters, numbers, periods, underscores, and hyphens
```

Maximum username length:

```text
20 characters
```

#### Configure Power and Sleep Settings

Allows the technician to configure sleep timeouts for:

- Plugged-in power
- Battery power

Timeout values are entered in whole minutes.

```text
0 minutes = Never
```

Supported timeout range:

```text
0 to 1440 minutes
```

The deployment tool displays the current settings, validates new values, shows a confirmation preview, skips settings that are already applied, and verifies successful changes.

### Deployment Validation

The deployment validation report performs read-only checks to determine whether a device is ready for issuance.

Current checks:

- Administrator access
- Internet connectivity
- Winget availability
- Computer naming
- Local standard user created by the deployment tool
- Additional applications marked as required for issuance
- Power and sleep configuration
- CrowdStrike sensor installation
- Supported Microsoft Office installation
- Pending Windows restart

A failed check does not change the computer. It identifies an item that requires technician attention before device issuance.

Validation results are also written to the active deployment log. Passed checks are recorded as `SUCCESS`, while failed readiness checks are recorded as `WARNING`.

Failed validation checks do not mean the validation process failed. They identify items that require technician attention before device issuance.

The local standard user check verifies that at least one enabled, non-administrator local account created by the deployment tool exists. Accounts are identified using the description `Created by IT Deployment Tool`.

The required application check reads the `RequiredForIssuance` property from `Config/Applications.json`. It reports any configured required applications that are not detected on the device.

### Deployment Logs

- Creates a separate deployment log for every session
- Records the computer name, logged-in user, and tool version
- Records installed, skipped, failed, and missing applications
- Records the final installation summary
- Records session start and completion times
- Displays the ten most recent deployment logs
- Sorts logs from newest to oldest
- Allows a selected log to be viewed directly in PowerShell
- Shows the log filename, modification date, and contents
- Supports refreshing the log list
- Opens the `Logs` directory in File Explorer

### User Interface

- Provides an interactive PowerShell menu
- Displays applications using selectable checkboxes
- Groups applications by category
- Supports navigation between the main menu and submenus
- Refreshes installed application status after processing
- Refreshes menus after completing an action
- Displays clear success, warning, and error messages
- Clears and redraws the main menu after returning from a submenu
- Ignores empty menu input instead of displaying an invalid-selection error

---

## Application Menu Controls

| Option | Action |
|:------:|--------|
| Number | Select or deselect an individual application |
| `A` | Select all applications |
| `R` | Select recommended applications |
| `C` | Clear all selections |
| `I` | Preview and install selected applications |
| `U` | Uninstall selected applications |
| `Q` | Return to the main menu |

---

## Project Structure

```text
IT Deployment Tool/
├── Config/
│   └── Applications.json
├── Installers/
│   ├── EXE/
│   │   ├── CrowdStrike/
│   │   └── SAP/
│   ├── MSI/
│   ├── ISO/
│   │   └── Office2024/
│   ├── IMG/
│   │   └── Office2021LOP/
│   ├── ZIP/
│   └── Scripts/
├── Logs/
│   └── .gitkeep
├── Modules/
│   ├── Applications/
│   │   ├── ApplicationCatalog.ps1
│   │   ├── ApplicationProcessCheck.ps1
│   │   ├── ApplicationSelection.ps1
│   │   ├── InstalledApplications.ps1
│   │   └── MicrosoftTeams.ps1
│   ├── Core/
│   │   ├── Elevation.ps1
│   │   ├── Logging.ps1
│   │   └── UI.ps1
│   ├── Installation/
│   │   ├── CrowdStrikeInstaller.ps1
│   │   ├── InstallationQueue.ps1
│   │   ├── InstallationResult.ps1
│   │   ├── InstallationRouter.ps1
│   │   ├── InstallerDirectories.ps1
│   │   ├── MsiInstaller.ps1
│   │   ├── Office2021ImgInstaller.ps1
│   │   ├── OfficeIsoInstaller.ps1
│   │   ├── OfflineInstaller.ps1
│   │   ├── ScriptInstaller.ps1
│   │   ├── WingetInstaller.ps1
│   │   └── ZipInstaller.ps1
│   ├── Interface/
│   │   ├── Application.ps1
│   │   ├── ApplicationMenu.ps1
│   │   ├── DeploymentLogs.ps1
│   │   ├── DeploymentLogsMenu.ps1
│   │   ├── Menu.ps1
│   │   ├── SelectedApplicationsSetup.ps1
│   │   └── WindowsConfigurationMenu.ps1
│   ├── Validation/
│   │   ├── DeploymentValidation.ps1
│   │   ├── InstallerPackageReadiness.ps1
│   │   ├── SystemChecks.ps1
│   │   └── SystemInformation.ps1
│   └── Windows/
│       ├── ComputerNameConfiguration.ps1
│       ├── LocalUserConfiguration.ps1
│       ├── PowerConfiguration.ps1
│       └── WindowsConfiguration.ps1
├── .gitignore
├── README.md
├── TESTING.md
└── Start.ps1
```

> Installer packages and generated log files are excluded from the repository.
> PowerShell modules are organized by responsibility and loaded by `Start.ps1` using an explicit dependency-aware order.

---

## Application Configuration

Applications are configured inside:

```text
Config/Applications.json
```

Each application entry may define:

- Application name
- Detection name
- Installation type
- WinGet package ID
- Offline installer path
- Offline uninstaller script path
- Silent installation arguments
- Silent uninstallation arguments
- Accepted success exit codes
- Restart exit codes
- Category
- Description
- Recommended status
- Required-for-issuance status
- WinGet installation scope
- Installed-application detection method
- Installed-application detection path
- Installed-application AppX/MSIX package name
- Blocking process names

The optional `RequiredForIssuance` property identifies applications that must be installed before a device is considered ready for issuance.

Applications without this property default to `false`.

The optional `DetectionPath` property overrides all other detection methods with a direct file-existence check. When configured, the application is considered installed if the specified absolute file path exists on the device. This is intended for applications with no installer and no registry trace, such as a portable tool copied to a fixed location by a Script-type installer.

The optional `AppxPackageName` property overrides all other detection methods by checking for an installed AppX/MSIX package with the given package family name. This is intended for applications distributed only through the Microsoft Store, which do not create classic Add/Remove Programs registry entries — for example, WhatsApp Desktop, which installs as the `5319275A.WhatsAppDesktop` package. When configured, this property is also used to uninstall the application, via `Remove-AppxPackage`, regardless of the application's `InstallType`.

The optional `UninstallArguments` property applies to offline EXE applications only. It appends a silent-uninstall flag to the vendor's registry `UninstallString` when the installer supports one (for example, `/S` for many NSIS-based installers). If omitted, the registry uninstall command runs as-is, which may open an interactive uninstaller.

The optional `UninstallerPath` property applies to Script-type applications only. It points to a dedicated uninstall script, relative to the `Installers` directory, the same way `InstallerPath` points to the install script. Script installers can perform arbitrary actions, so there is no generic way to reverse one automatically — an application without a configured `UninstallerPath` cannot be uninstalled through the tool.

```json
{
  "Name": "Example Application",
  "InstallType": "Winget",
  "Winget": "Vendor.Application",
  "Recommended": true,
  "RequiredForIssuance": true
}
```

CrowdStrike and Microsoft Office are excluded from the general required application check because they have dedicated deployment validation checks.

### WinGet Application Example

```json
{
  "Name": "Google Chrome",
  "InstallType": "Winget",
  "Winget": "Google.Chrome",
  "Category": "Browsers",
  "Description": "Google web browser",
  "Recommended": true
}
```

### Blocking Process Example

Applications may define processes that must be closed before installation:

```json
{
  "Name": "Visual Studio Code",
  "InstallType": "Winget",
  "Winget": "Microsoft.VisualStudioCode",
  "WingetScope": "machine",
  "BlockingProcesses": [
    "Code"
  ]
}
```

> The blocking-process check runs only when the application is not already installed. Already-installed applications are skipped before process detection.
> When a configured process is running, the technician may close the application and retry the check or skip that application. Skipping does not stop the remaining installation queue.

### Offline EXE Application Example

```json
{
  "Name": "SAP GUI for Windows 7.70",
  "DetectionName": "SAP GUI for Windows 7.70",
  "InstallType": "Exe",
  "InstallerPath": "SAPGUI-7.70-WINDOWS_50152942_2\\BD_NW_7.0_Presentation_7.70_Comp._1_\\PRES1\\GUI\\Windows\\Win32\\SapGuiSetup.exe",
  "SilentArguments": "",
  "SuccessExitCodes": [0, 129],
  "RebootExitCodes": [129],
  "Category": "Company Applications",
  "Description": "SAP GUI client used by the company",
  "Recommended": true
}
```

### CrowdStrike Application Example

```json
{
  "Name": "CrowdStrike Windows Sensor",
  "DetectionName": "CrowdStrike Windows Sensor",
  "InstallType": "CrowdStrike",
  "Category": "Security",
  "Description": "CrowdStrike Falcon endpoint security sensor",
  "Recommended": true
}
```

CrowdStrike does not require an installer path in `Applications.json`. Its dedicated module searches inside:

```text
Installers/CrowdStrike/
```

---

## Offline Installers

Offline installer files are stored inside the `Installers` directory.

These files are excluded from the Git repository because they may be:

- Large
- Proprietary
- Licensed
- Company-specific
- Security-sensitive

After cloning the repository, the required installer files must be manually placed inside `Installers` using the expected directory structure.

Offline installer packages are organized by package type:

- `Installers/EXE/` - executable installers
- `Installers/MSI/` - Windows Installer packages
- `Installers/ISO/` - ISO-based deployment packages
- `Installers/IMG/` - disc image deployment packages
- `Installers/ZIP/` - compressed deployment packages
- `Installers/Scripts/` - supporting deployment scripts

Required installer directories are created automatically when the deployment tool starts.

### SAP GUI Example

```text
Installers/
`-- SAPGUI-7.70-WINDOWS_50152942_2/
    `-- BD_NW_7.0_Presentation_7.70_Comp._1_/
        `-- PRES1/
            `-- GUI/
                `-- Windows/
                    `-- Win32/
                        `-- SapGuiSetup.exe
```

### CrowdStrike Example

```text
Installers/
`-- CrowdStrike/
    |-- FalconSensor_Windows - 7.35.20709.exe
    `-- Readme.txt
```

The CrowdStrike README is expected to contain:

```text
Customer ID: <company CID with checksum>
Token: <installation token>
Maintenance Token: <maintenance token>
```

`Customer ID` and `Token` are read and used by this tool to install the sensor. `Maintenance Token` is for a technician's own manual reference only — this tool does not read, parse, or act on it. CrowdStrike uninstallation is not automated by this tool (see [Uninstallation Automation](#uninstallation-automation) above); removing the sensor requires CrowdStrike's own `CsUninstallTool.exe` (downloaded separately from the Falcon console's Tool Downloads page) run by hand as `CsUninstallTool.exe MAINTENANCE_TOKEN=<token> /quiet`, or without the token if Maintenance Protection is disabled in the Falcon console.

Do not commit or publicly share the real values.

---

## Deploying to a New Machine

The tool is copied to each machine rather than installed through a package manager. When setting up a brand new company laptop:

1. **Get the code onto the machine.** Clone or copy this repository. Everything except the `Installers\` directory's actual package files travels with it automatically, including the bundled Nunito font used by the GUI (`Modules\Gui\Fonts\`).
2. **Transfer the offline installer packages separately.** `Installers\` is deliberately excluded from Git (see [Offline Installers](#offline-installers) above) because its contents are large, proprietary, licensed, or security-sensitive. On a machine that already has these staged, the directory structure under `Installers\` can be copied as-is onto the new machine — the exact transfer method (external drive, network share, cloud storage) isn't dictated by this tool and is still an open decision for this project; whichever is used, preserve the existing subfolder structure (`Installers\EXE\...`, `Installers\ISO\...`, etc.) exactly, since the application catalog's `InstallerPath` values are matched against it directly.
3. **Validate before doing anything else.** Run `.\Start.ps1 -ValidateOnly` first. This is read-only, requests no elevation, and confirms the module set loads correctly and `Config\Applications.json` is present — a fast way to catch a broken transfer before ever touching the new machine's real configuration.
4. **Check installer package readiness.** From the console menu or the GUI's Deployment Validation screen, review which offline packages report `READY` vs. `MISSING` — this shows exactly which `Installers\` subfolders didn't make the transfer, before attempting an install that would otherwise fail partway through.
5. **Run the tool for real**, either `.\Start.ps1` (console) or `.\Start.ps1 -Gui` (graphical). WinGet-based applications install directly from the internet and need no local files; only EXE/MSI/ISO/IMG/ZIP/Script-type applications depend on `Installers\` being populated.

### Self-Removal on Devices Set Up via the Remote Bootstrap

A device set up via the one-line remote bootstrap (`irm https://raw.githubusercontent.com/I-Descry/it-deployment-tool/main/Deploy.ps1 | iex`, which downloads the tool to `Desktop\IT Deployment Tool` and launches it — see `Deploy.ps1` at the repo root) behaves differently when its window closes: closing it asks **"This will permanently delete the IT Deployment Tool from this device... Continue?"**, and confirming permanently deletes the entire tool folder from that device — scripts, config, downloaded `Installers\` packages, and `Logs\`. **The applications it installed are never touched, only the tool itself.**

This only ever happens on a device set up through that exact bootstrap flow. A manually cloned or copied repository (including this dev repository) never asks this and never self-deletes, since only `Deploy.ps1`'s own launch line enables it. Declining the confirmation just closes the window normally, with nothing deleted.

### Fixed Issue: WinGet Apps No Longer Falsely Report "Not Found"

Earlier versions of this tool could report **Not Found** for a WinGet-based application (e.g. Google Chrome) even though the package genuinely existed and `winget install` for it worked fine. Root cause: the availability check ran `winget show --id ...` to confirm a package existed before ever attempting the install, and that specific command can fail on a device running an elevated process (this tool always runs elevated) even though `winget install` for the same package succeeds on the same device -- most likely related to [CVE-2026-68821](https://www.sentinelone.com/vulnerability-database/cve-2026-68821/), a WinGet privilege-escalation flaw Microsoft patched in App Installer 1.29.280, which appears to have tightened what an elevated process can read from WinGet's local source data.

The fix: the availability check (`Test-WingetPackage`, `Modules\Installation\WingetInstaller.ps1`) no longer calls `winget show` to verify a specific package exists -- it only confirms the `winget` command itself is present. The actual `winget install` call (which already has robust exit-code handling) is now the real source of truth for whether a given package installs; a genuinely nonexistent Winget ID surfaces as a `Failed` result with winget's real error message at install time, instead of a `Not Found` before ever trying.

If a WinGet install still fails for some other reason, the deployment log will show the real winget exit code/message from the actual install attempt rather than a generic "Not Found."

### Self-Healing: WinGet Source-Data-Missing Errors Recover Automatically

On one real device, even the actual `winget install`/`winget uninstall` calls (not just the availability check above) started failing with exit code `-1978335217` (`0x8A15000F`, "Data required by the source is missing"), tied to the same elevation-related WinGet behavior. The real, confirmed fix was re-registering a specific AppX package, `Microsoft.Winget.Source` (the piece that holds WinGet's actual source index data, separate from the main App Installer package), from its existing files -- no reinstall or removal needed.

This tool now does that automatically: if a WinGet install or uninstall fails with exactly that exit code, it re-registers `Microsoft.Winget.Source` and retries the same command once before reporting a real failure. This only ever triggers on that exact, specific exit code, so it never masks a genuinely different WinGet problem -- and it only re-registers files already present on the device, it never removes or reinstalls anything. No technician action is needed if a future device hits this same issue.

---

## Deployment Logs

Deployment logs are automatically created inside:

```text
Logs/
```

Each session creates a separate `.log` file containing:

- Tool version
- Computer name
- Logged-in user
- Session start time
- Application processing results
- Installation summary
- Session completion time

Generated log files are excluded from Git.

CrowdStrike credentials must never appear in deployment logs.

---

## Running the Tool

Open PowerShell in the project directory and run:

```powershell
.\Start.ps1
```

The tool automatically requests administrator privileges when elevation is required.

---

### GUI Mode

A WPF graphical interface is available as an alternative to the console menus, styled after the approved design mockup (dark theme, custom title bar, sidebar navigation):

```powershell
.\Start.ps1 -Gui
```

Administrator elevation is requested before the window opens, exactly like console mode. The GUI covers the same functionality as the console menus: Applications (browse, select, install, uninstall — install/uninstall run in the background so the window stays responsive), Windows Configuration (device information, computer rename, local standard user creation, power and sleep settings), Deployment Logs (browse and view recent session logs), and Deployment Validation (device readiness checks and installer package status).

---

### Validation Mode

The deployment tool can perform a read-only startup validation without requesting administrator elevation or opening the main menu.

```powershell
.\Start.ps1 -ValidateOnly
```

---

## Typical Workflow

1. Start the deployment tool.
2. Review the displayed system information and status checks.
3. Open the Install Applications menu.
4. Select applications individually, select all, or select recommended applications.
5. Press `I` to preview the selected applications.
6. Confirm or cancel the installation.
7. Allow the installation queue to process each selected application.
8. Review the installation summary.
9. Open Configure Windows when device preparation is required.
10. Review the current Windows configuration.
11. Rename the computer using the `POSITION-NAME` standard when required.
12. Create the employee's local standard user.
13. Configure the plugged-in and battery sleep settings.
14. Open Deployment Logs to inspect session activity.
15. Activate Microsoft Office manually using an authorized product key when Office installation is included.

For CrowdStrike installation, the technician must review the populated setup fields, manually accept the Sensor Terms of Use, and click Install.

---

## Security Notes

- Do not store passwords, tokens, Customer IDs, or secrets inside tracked PowerShell files.
- Do not place credentials inside `Applications.json`.
- Do not commit CrowdStrike installer packages or credential files.
- Do not write CrowdStrike installation arguments to deployment logs.
- Restrict access to the local CrowdStrike package directory.
- Test CrowdStrike installation only on authorized company devices.
- Microsoft Office product-key activation remains manual until new company-approved keys are available for secure automation.

---

## Purpose

This project was created to improve the consistency and efficiency of Windows device deployment by combining application selection, installation automation, installed-application detection, offline installer support, company application support, and deployment logging into one modular PowerShell tool.