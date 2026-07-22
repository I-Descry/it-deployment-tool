# IT Deployment Tool

A modular PowerShell-based deployment tool designed to automate application installation and simplify the setup of new Windows devices.

Instead of manually downloading and installing applications one at a time, the tool provides a single interactive interface for selecting and processing multiple applications. It reduces repetitive work, saves deployment time, minimizes manual errors, and helps maintain a consistent device setup process.

---

## Current Version

`0.9.0`

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
- Supports individual application selection
- Supports selecting multiple applications
- Supports Select All and Clear All options
- Supports automatic selection of recommended applications
- Validates configured WinGet package IDs
- Tracks selections using interactive checkboxes

### Installation Automation

- Detects installed applications through the Windows Registry
- Skips applications that are already installed
- Processes selected applications sequentially
- Supports silent installation through WinGet
- Supports local offline EXE installers
- Routes applications according to their configured installation type
- Validates offline installer files before execution
- Supports application-specific success exit codes
- Detects when an installer recommends a system restart
- Continues processing when an application is skipped or fails
- Displays a final installation summary
- Supports company applications such as SAP GUI

### Recommended Applications Setup

- Uses the `Recommended` property from `Config/Applications.json`
- Automatically selects applications marked as recommended
- Displays a preview before processing
- Shows each application's category and installation type
- Requires confirmation before installation
- Supports safe cancellation
- Uses the standard installation queue
- Uses existing installed-application detection

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
- Refreshes menus after completing an action
- Displays clear success, warning, and error messages

---

## Application Menu Controls

| Option | Action |
|:------:|--------|
| `A` | Select all applications |
| `R` | Select recommended applications |
| `P` | Preview and process the recommended setup |
| `C` | Clear all selections |
| `I` | Install selected applications |
| `Q` | Return to the main menu |
| Number | Toggle an individual application |

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
│   ├── RecommendedSetup.ps1
│   ├── SystemChecks.ps1
│   ├── SystemInformation.ps1
│   ├── UI.ps1
│   └── WingetInstaller.ps1
├── .gitignore
├── README.md
└── Start.ps1
```

---

## Application Configuration

Applications are configured inside:

```text
Config/Applications.json
```

Each application entry defines information such as:

- Application name
- Detection name
- Installation type
- WinGet package ID or offline installer path
- Silent installation arguments
- Accepted success exit codes
- Restart exit codes
- Category
- Description
- Recommended status

Example WinGet application:

```json
{
  "Name": "Google Chrome",
  "DetectionName": "Google Chrome",
  "InstallType": "Winget",
  "WingetId": "Google.Chrome",
  "Category": "Browsers",
  "Description": "Google Chrome web browser",
  "Recommended": true
}
```

Example offline EXE application:

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

---

## Offline Installers

Offline installer files are stored inside the `Installers` directory.

These files are excluded from the Git repository because they may be:

- Large
- Proprietary
- Licensed
- Company-specific

After cloning the repository, required offline installer files must be manually placed inside the `Installers` directory using the folder structure configured in `Applications.json`.

Example:

```text
Installers/
└── SAPGUI-7.70-WINDOWS_50152942_2/
    └── BD_NW_7.0_Presentation_7.70_Comp._1_/
        └── PRES1/
            └── GUI/
                └── Windows/
                    └── Win32/
                        └── SapGuiSetup.exe
```

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
5. Preview the recommended setup when needed.
6. Start the installation queue.
7. Review the installation summary.
8. Open Deployment Logs to inspect session activity.

---

## Purpose

This project was created to improve the consistency and efficiency of Windows device deployment by combining application selection, installation automation, installed-application detection, offline installer support, recommended setup workflows, and deployment logging into one modular PowerShell tool.