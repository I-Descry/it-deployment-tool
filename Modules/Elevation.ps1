# ============================================================
# ADMINISTRATOR ELEVATION
# ============================================================

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

