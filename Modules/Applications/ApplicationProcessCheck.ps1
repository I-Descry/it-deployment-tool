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

function Resolve-BlockingApplicationProcesses {
  param(
    [Parameter(Mandatory)]
    [PSCustomObject]$Application
  )

  while ($true) {
    $BlockingProcesses = @(Get-BlockingApplicationProcesses -Application $Application)

    if ($BlockingProcesses.Count -eq 0) {
      return [PSCustomObject]@{
        Status       = "Clear"
        ProcessNames = @()
      }
    }

    $BlockingProcessNames = @($BlockingProcesses | Select-Object -ExpandProperty ProcessName -Unique | Sort-Object)

    Write-Host
    Write-Host ("{0} cannot be installed while these processes are running: {1}" -f $Application.Name, ($BlockingProcessNames -join ", ")) -ForegroundColor Yellow

    Write-Host
    Write-Host "[R] Retry after closing the application"
    Write-Host "[S] Skip this application"

    $Selection = ([string](Read-Host "Select an option")).Trim().ToUpperInvariant()

    switch ($Selection) {
      "R" {
        continue
      }

      "S" {
        return [PSCustomObject]@{
          Status       = "Blocked"
          ProcessNames = @($BlockingProcessNames)
        }
      }

      default {
        Write-Host
        Write-Host "Invalid selection. Enter R or S." -ForegroundColor Yellow
      }
    }
  }
}