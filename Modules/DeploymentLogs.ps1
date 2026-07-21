# ============================================================
# DEPLOYMENT LOGS
# ============================================================

function Get-DeploymentLogs {
  param(
    [int]$MaximumResults = 10
  )

  $LogsDirectory = Join-Path $PSScriptRoot "..\Logs"

  if (-not (Test-Path -LiteralPath $LogsDirectory)) {
    return @()
  }

  return @(
    Get-ChildItem -LiteralPath $LogsDirectory -Filter "*.log" -File -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First $MaximumResults
  )
}

function Get-DeploymentLogContent {
  param(
    [Parameter(Mandatory)]
    [System.IO.FileInfo]$LogFile
  )

  if (-not (
    Test-Path -LiteralPath $LogFile.FullName -PathType Leaf
  )) {
    throw "Deployment log filewas not found."
  }

  return @(
    Get-Content -LiteralPath $LogFile.FullName -ErrorAction Stop
  )
}

function Open-DeploymentLogsFolder {
  $LogsDirectory = Join-Path $PSScriptRoot "..\Logs"

  if (-not (
    Test-Path -LiteralPath $LogsDirectory -PathType Container
  )) {
    New-Item -Path $LogsDirectory -ItemType Directory -Force | Out-Null
  }

  Start-Process -FilePath $LogsDirectory -ErrorAction Stop
}