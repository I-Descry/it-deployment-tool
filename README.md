# IT Deployment Tool

A modular PowerShell-based deployment tool created to automate application installation when setting up new Windows devices.

Instead of manually downloading and installing each application one by one, the tool allows me to select multiple required applications and install them automatically through a single interface. This reduces repetitive work, saves deployment time, minimizes human effort, and helps me make future device setups more consistent.

---

## Current Version

`0.5.0-dev`

---

## Features

- Displays device information
- Checks administrator privileges
- Automatically requests administrator elevation
- Checks internet connectivity
- Checks WinGet availability
- Loads applications from a JSON configuration file
- Groups applications by category
- Supports multiple application selection
- Validates WinGet package IDs
- Detects applications already installed through the Windows Registry
- Skips applications that are already installed
- Installs selected applications sequentially
- Supports silent WinGet installation

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
│   ├── Installer.ps1
│   ├── Menu.ps1
│   ├── System.ps1
│   └── UI.ps1
├── .gitignore
├── README.md
└── Start.ps1
```