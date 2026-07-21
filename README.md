# IT Deployment Tool

A modular PowerShell-based deployment tool created to automate application installation when setting up new Windows devices.

Instead of manually downloading and installing each application one by one, the tool allows me to select multiple required applications and install them automatically through a single interface. This reduces repetitive work, saves deployment time, minimizes human effort, and helps me make future device setups more consistent.

---

## Current Version

`0.8.0`

---

## Features

### System Information and Requirements

- Displays device information
- Checks administrator privileges
- Automatically requests administrator elevation
- Checks internet connectivity
- Checks WinGet availability

### Application Management

- Loads applications from a JSON configuration file
- Groups applications by category
- Supports individual and multiple application selection
- Supports Select All and Clear All options
- Validates WinGet package IDs

### Installation Automation

- Detects applications already installed through the Windows Registry
- Skips applications that are already installed
- Installs selected applications sequentially
- Supports silent installation through WinGet
- Continues processing the installation queue when an application is skipped or fails
- Displays an installation results summary
- Supports online application installation through WinGet
- Supports local offline EXE installers
- Routes applications based on their configured installation type
- Validates offline installer files before execution
- Supports application-specific success exit codes
- Detects when an installer recommends a restart
- Supports company applications such as SAP GUI

### Deployment Logs

- Creates a seperate deployment log for every session
- Records the computer name, logged-in user, and tool version
- Records installed, skipped, failed, and missing applications
- Records the final installation summary
- Records deployment session start and completion times
- Displays the ten most recent deployment logs
- Sorts logs from newest to oldest
- Allows logs to be selected and viewed inside PowerShell
- Shows the log filename, modification date, and contents
- Supports refreshing the log list
- Opens the Logs directory in File Explorer

### User Interface

- Provides an interactive PowerShell menu
- Displays applications using selectable checkboxes
- Supports navigation between the application menu and main menu
- Refreshes the main menu after returning from a submenu

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
│   ├── Elevation.ps1
│   ├── DeploymentLogs.ps1
│   ├── DeploymentLogsMenu.ps1
│   ├── InstallationQueue.ps1
│   ├── InstallationRouter.ps1
│   ├── InstalledApplications.ps1
│   ├── Logging.ps1
│   ├── Menu.ps1
│   ├── OfflineInstaller.ps1
│   ├── SystemChecks.ps1
│   ├── SystemInformation.ps1
│   ├── UI.ps1
│   └── WingetInstaller.ps1
├── .gitignore
├── README.md
└── Start.ps1
```

## Offline Installers

Offline installer files are stored inside the `Installers` directory.

These files are excluded from the Git repository because they may be large, proprietary, or company-specific. After cloning the project, the required installer folders and files must be placed manually inside `Installers`.

Example:

```text
Installers/
└── SAPGUI-7.70-WINDOWS_50152942_2/
    └── ...
        └── SapGuiSetup.exe