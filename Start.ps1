# ============================================================
# IT Deployment Tool
# Version 0.6.1-dev
# Author : IT04 - John Paul Villacorta
# ============================================================

# ============================================================
# Application Information
# ============================================================

$AppName = "IT DEPLOYMENT TOOL"
$AppVersion = "0.6.1-dev"
$AppAuthor = "IT04 - John Paul Villacorta"

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

Get-ChildItem -Path "$PSScriptRoot\Modules" -Filter "*.ps1" | Sort-Object Name | ForEach-Object {
  . $_.FullName
}

$AdministratorGranted = Request-Administrator -ScriptPath $PSCommandPath

if (-not $AdministratorGranted) {
  exit
}

# ============================================================
# Application Starts Here
# ============================================================

Start-Application