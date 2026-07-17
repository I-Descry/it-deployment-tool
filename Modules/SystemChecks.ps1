# ============================================================
# SYSTEM CHECKS
# ============================================================

function Test-Administrator {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object Security.Principal.WindowsPrincipal($identity)

  $SystemInfo.IsAdministrator = $principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
  )
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
