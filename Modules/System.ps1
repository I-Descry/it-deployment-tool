function Get-SystemInformation {
    $SystemInfo.ComputerName = $env:COMPUTERNAME
    $SystemInfo.LoggedUser = $env:USERNAME

    $ComputerSystem = Get-CimInstance Win32_ComputerSystem

    $SystemInfo.Manufacturer = $ComputerSystem.Manufacturer
    $SystemInfo.Model = $ComputerSystem.Model
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

function Test-Administrator {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object Security.Principal.WindowsPrincipal($identity)

  $SystemInfo.IsAdministrator = $principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
  )
}

function Request-Administrator {
  param(
    [Parameter(Mandatory)]
    [string]$ScriptPath
  )

  Test-Administrator

  if ($SystemInfo.IsAdministrator) {
    return $true
  }

  Write-Host
  Write-Host "Administrator access is required." -ForegroundColor Yellow
  Write-Host "Requesting administrator access..."

  $PowerShellPath = (Get-Process -Id $PID).Path
  $WorkingDirectory = Split-Path -Path $ScriptPath -Parent

  $PowerShellArguments = @(
    "-NoProfile"
    "-ExecutionPolicy"
    "Bypass"
    "-File"
    "`"$ScriptPath`""
  )

  try {
    Start-Process -FilePath $PowerShellPath -ArgumentList $PowerShellArguments -WorkingDirectory $WorkingDirectory -Verb RunAs -ErrorAction Stop

    return $false
  }

  catch {
    Write-Host
    Write-Host "Administrator access was not granted." -ForegroundColor Red
    Pause-Application

    return $false
  }
}
function Test-Internet {
  $SystemInfo.InternetStatus = Test-Connection `
      -ComputerName "8.8.8.8" `
      -Count 1 `
      -Quiet
}

function Test-Winget {
  $winget = Get-Command winget -ErrorAction SilentlyContinue
  $SystemInfo.WingetAvailable = ($null -ne $winget)
}