# ============================================================
# APPLICATION PROCESS CHECK
# ============================================================

function Get-BlockingApplicationProcesses {
  param(
    [Parameter(Mandatory)]
    [PSCustomObject]$Application
  )

  $ConfiguredProcesses = @($Application.BlockingProcesses | Where-Object {
    -not [string]::IsNullOrWhiteSpace([string]$_)
  })

  if ($ConfiguredProcesses.Count -eq 0) {
    return @()
  }

  $RunningProcesses = foreach ($ConfiguredProcess in $ConfiguredProcesses) {
    $ProcessName = [System.IO.Path]::GetFileNameWithoutExtension([string]$ConfiguredProcess)

    Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
  }

  return @($RunningProcesses | Sort-Object Id -Unique)
}