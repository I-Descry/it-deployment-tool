# IT Deployment Tool

A modular PowerShell-based deployment tool designed to automate application installation and simplify the setup of new Windows devices.

Instead of manually downloading and installing applications one at a time, the tool provides a single interactive interface for selecting and processing multiple applications. It reduces repetitive work, saves deployment time, minimizes manual errors, and helps maintain a consistent device setup process.

---

## Current Version

`1.1.0-dev`

This development version adds CrowdStrike Falcon Sensor integration. The installed-device detection and skip workflow have been tested. The interactive installation and automatic credential population still require final testing on an authorized device where CrowdStrike is not installed.

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
│   └── .gitkeep
├── Logs/
│   └── .gitkeep
├── Modules/
│   ├── Application.ps1
│   ├── ApplicationCatalog.ps1
│   ├── ApplicationMenu.ps1
│   ├── ApplicationSelection.ps1
│   ├── DeploymentLogs.ps1
│   ├── DeploymentLogsMenu.ps1
│   ├── Elevation.ps1
│   ├── InstallationQueue.ps1
│   ├── InstallationRouter.ps1
│   ├── InstalledApplications.ps1
│   ├── Logging.ps1
│   ├── Menu.ps1
│   ├── OfflineInstaller.ps1
│   ├── SelectedApplicationsSetup.ps1
│   ├── SystemChecks.ps1
│   ├── SystemInformation.ps1
│   ├── UI.ps1
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
9. Open Deployment Logs to inspect session activity.

For CrowdStrike installation, the technician must review the populated setup fields, manually accept the Sensor Terms of Use, and click Install.

---

## Security Notes

- Do not store passwords, tokens, Customer IDs, or secrets inside tracked PowerShell files.
- Do not place credentials inside `Applications.json`.
- Do not commit CrowdStrike installer packages or credential files.
- Do not write CrowdStrike installation arguments to deployment logs.
- Restrict access to the local CrowdStrike package directory.
- Test CrowdStrike installation only on authorized company devices.

---

## Purpose

This project was created to improve the consistency and efficiency of Windows device deployment by combining application selection, installation automation, installed-application detection, offline installer support, company application support, and deployment logging into one modular PowerShell tool.