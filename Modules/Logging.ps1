# ============================================================
# DEPLOYMENT LOGGING
# ============================================================

$script:LogFilePath = $null

function Write-DeploymentLog {
  param(
    [Parameter(Mandatory)]
    [string]$Message,

    [ValidateSet(
      "INFO",
      "SUCCESS",
      "WARNING",
      "ERROR"
    )]
    [string]$Level = "INFO"
  )

  if ([string]::IsNullOrWhiteSpace($script:LogFilePath)) {
    return
  }

  $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $LogEntry = "{0} [{1}] {2}" -f $Timestamp, $Level, $Message

  Add-Content -Path $script:LogFilePath -Value $LogEntry -Encoding UTF8
}

function Initialize-DeploymentLog {
  param(
    [Parameter(Mandatory)]
    [string]$Version
  )

  $LogsDirectory = Join-Path $PSScriptRoot "..\Logs"

  if (-not (Test-Path $LogsDirectory)) {
    New-Item -ItemType Directory -Path $LogsDirectory -Force | Out-Null
  }

  $Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

  $LogFileName = "Deployment_{0}_{1}.log" -f $env:COMPUTERNAME, $Timestamp
  
  $script:LogFilePath = Join-Path $LogsDirectory $LogFileName

  @(
    "============================================================"
    "IT DEPLOYMENT TOOL LOG"
    "============================================================"
    "Version       : $Version"
    "Computer Name : $env:COMPUTERNAME"
    "Logged User   : $env:USERNAME"
    "Started       : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "============================================================"
    ""
  ) | Set-Content -Path $script:LogFilePath -Encoding UTF8

  Write-DeploymentLog -Message "Deployment session started"
}

function Complete-DeploymentLog {
  if ([string]::IsNullOrWhiteSpace($script:LogFilePath)) {
    return
  }

  Write-DeploymentLog -Message "Deployment session completed." -Level "SUCCESS"

  @(
    ""
    "============================================================"
    "Ended         : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "============================================================"
  ) | Add-Content -Path $script:LogFilePath -Encoding UTF8

  $script:LogFilePath = $null
}