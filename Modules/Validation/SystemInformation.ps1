# ============================================================
# SYSTEM INFORMATION
# ============================================================

function Get-SystemInformation {
    $SystemInfo.ComputerName = $env:COMPUTERNAME
    $SystemInfo.LoggedUser = $env:USERNAME

    $ComputerSystem = Get-CimInstance Win32_ComputerSystem
    $OperatingSystem = Get-CimInstance Win32_OperatingSystem

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