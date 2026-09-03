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

  # Test-Connection's underlying WMI ping has no configurable timeout in Windows PowerShell 5.1 and can block for several seconds on a network that silently drops outbound ICMP (common behind corporate firewalls). System.Net.NetworkInformation.Ping exposes an explicit timeout so this check can never stall the GUI's startup beyond it.
  try {
    $Ping = New-Object System.Net.NetworkInformation.Ping
    $Reply = $Ping.Send("8.8.8.8", 1000)
    $InternetAvailable = ($Reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success)
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
  # Delegates to Test-WingetAvailable (Installation\WingetInstaller.ps1, loaded later but already defined by the time this function is ever called, same as every other cross-module call in this app) rather than a plain Get-Command, since a bare Get-Command check reported red/unavailable on a real device where the elevated session was running as a different account (e.g. the Built-in Administrator) than the real interactively logged-on user -- winget's own app execution alias is per-user, so that account genuinely did not have it on PATH even though the real user's own session did.
  [CmdletBinding()]
  param(
    [switch]$PassThru
  )

  $WingetAvailable = Test-WingetAvailable

  $SystemInfo.WingetAvailable = $WingetAvailable

  if ($PassThru) {
    return $WingetAvailable
  }
}