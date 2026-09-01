# ============================================================
# SYSTEM INFORMATION
# ============================================================

function Get-SystemInformation {
    $SystemInfo.ComputerName = $env:COMPUTERNAME

    $ComputerSystem = Get-CimInstance Win32_ComputerSystem
    $OperatingSystem = Get-CimInstance Win32_OperatingSystem

    # Win32_ComputerSystem.UserName reflects the real interactively logged-on user even when this process itself is elevated as a different account (e.g. the Built-in Administrator used to elevate a standard local user's session), unlike $env:USERNAME which only ever reflects this process's own identity; falls back to $env:USERNAME if it's ever blank. Same source already used for Device Details' own Logged User field (WindowsConfiguration.ps1), stripped of its "COMPUTERNAME\" prefix here to keep matching this compact bar's existing bare-username display.
    $RawLoggedUser = if (-not [string]::IsNullOrWhiteSpace([string]$ComputerSystem.UserName)) { [string]$ComputerSystem.UserName } else { $env:USERNAME }
    $SystemInfo.LoggedUser = $RawLoggedUser.Split('\')[-1]

    $SystemInfo.Manufacturer = $ComputerSystem.Manufacturer
    $SystemInfo.Model = $ComputerSystem.Model
    $SystemInfo.WindowsEdition = $OperatingSystem.Caption
}

function Show-SystemInformation {

  Write-Section "Device Information"

  Write-Info "Computer Name" $SystemInfo.ComputerName
  Write-Info "Logged User" $SystemInfo.LoggedUser
  Write-Info "Manufacturer" $SystemInfo.Manufacturer
  Write-Info "Model" $SystemInfo.Model

  Write-Section "Deployment Status"

  Write-Status "Administrator" $SystemInfo.IsAdministrator
  Write-Status "Internet" $SystemInfo.InternetStatus
  Write-Status "Winget" $SystemInfo.WingetAvailable
}