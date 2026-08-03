# IT Deployment Tool

A modular PowerShell-based deployment tool designed to automate application installation and simplify the setup of new Windows devices.

Instead of manually downloading and installing applications one at a time, the tool provides a single interactive interface for selecting and processing multiple applications. It reduces repetitive work, saves deployment time, minimizes manual errors, and helps maintain a consistent device setup process.

---

## Current Version

`1.1.0-dev`

This development version adds CrowdStrike deployment, Microsoft Office 2024 and Office 2021 LOP installation, and Windows device configuration features.

Fresh installations and final clean-device testing are still required before
releasing version `1.1.0`.

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

The deployment tool supports installing Microsoft Office Professional Plus
2021 Retail on authorized LOP laptops from a local disc image.

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
- Power and sleep configuration
- CrowdStrike sensor installation
- Supported Microsoft Office installation
- Pending Windows restart
- Additional applications marked as required for issuance

A failed check does not change the computer. It identifies an item that requires technician attention before device issuance.

Validation results are also written to the active deployment log. Passed checks are recorded as `SUCCESS`, while failed readiness checks are recorded as `WARNING`.

Failed validation checks do not mean the validation process failed. They identify items that require technician attention before device issuance.

The local standard user check verifies that at least one enabled, non-administrator local account created by the deployment tool exists. Accounts are identified using the description `Created by IT Deployment Tool`.

The required application check reads the `RequiredForIssuance` property from `Config/Applications.json`. It reports any configured required applications that are not detected on the device.

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
| `Q` | Return to the main menu |

---

## Project Structure

```text
IT Deployment Tool/
├── Config/
│   └── Applications.json
├── Installers/
│   ├── CrowdStrike/
│   ├── Office2021LOP/
│   │   └── ProPlus2021Retail.img
│   ├── Office2024/
│   │   └── ODT2024s.ISO
│   └── SAP/
├── Logs/
│   └── .gitkeep
├── Modules/
│   ├── Application.ps1
│   ├── ApplicationCatalog.ps1
│   ├── ApplicationMenu.ps1
│   ├── ApplicationSelection.ps1
│   ├── ComputerNameConfiguration.ps1
│   ├── CrowdStrikeInstaller.ps1
│   ├── DeploymentLogs.ps1
│   ├── DeploymentLogsMenu.ps1
│   ├── DeploymentValidation.ps1
│   ├── Elevation.ps1
│   ├── InstallationQueue.ps1
│   ├── InstallationRouter.ps1
│   ├── InstalledApplications.ps1
│   ├── LocalUserConfiguration.ps1
│   ├── Logging.ps1
│   ├── Menu.ps1
│   ├── Office2021ImgInstaller.ps1
│   ├── OfficeIsoInstaller.ps1
│   ├── OfflineInstaller.ps1
│   ├── PowerConfiguration.ps1
│   ├── SelectedApplicationsSetup.ps1
│   ├── SystemChecks.ps1
│   ├── SystemInformation.ps1
│   ├── UI.ps1
│   ├── WindowsConfiguration.ps1
│   ├── WindowsConfigurationMenu.ps1
│   └── WingetInstaller.ps1
├── .gitignore
├── README.md
└── Start.ps1
```

Installer packages and generated log files are excluded from the repository.

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
- Silent installation arguments
- Accepted success exit codes
- Restart exit codes
- Category
- Description
- Recommended status
- Required-for-issuance status

The optional `RequiredForIssuance` property identifies applications that must be installed before a device is considered ready for issuance.

Applications without this property default to `false`.

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
```

Do not commit or publicly share the real values.

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