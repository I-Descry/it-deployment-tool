# ============================================================
# SYSTEM CHECKS
# ============================================================

function Test-Administrator {
  [CmdletBinding()]
  param(
    [switch]$PassThru
  )

  try {
    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
    $IsAdministrator = [bool]$Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  }

  catch {
    $IsAdministrator = $false
  }

  $SystemInfo.IsAdministrator = $IsAdministrator

  if ($PassThru) {
    return $IsAdministrator
  }
}

function Test-Internet {
  [CmdletBinding()]
  param(
    [switch]$PassThru
  )

  try {
    $InternetAvailable = [bool](Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue)
  }

  catch {
    $InternetAvailable = $false
  }

  $SystemInfo.InternetStatus = $InternetAvailable

  if ($PassThru) {
    return $InternetAvailable
  }
}

function Test-Winget {
  [CmdletBinding()]
  param(
    [switch]$PassThru
  )

  $WingetCommand = Get-Command -Name "winget.exe" -ErrorAction SilentlyContinue
  $WingetAvailable = [bool]($null -ne $WingetCommand)

  $SystemInfo.WingetAvailable = $WingetAvailable

  if ($PassThru) {
    return $WingetAvailable
  }
}