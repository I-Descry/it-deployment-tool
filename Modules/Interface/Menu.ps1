# ============================================================
# MAIN MENU
# ============================================================

function Show-MainMenu {
  Write-Title -Title "MAIN MENU"

  Write-Section -Title "Deployment Status"

  Write-Host " [1] Install Applications"
  Write-Host " [2] Configure Windows"
  Write-Host " [3] Deployment Logs"
  Write-Host " [4] About"
  Write-Host " [5] Deployment Validation"
  Write-Host
  Write-Host " [0] Exit"
  Write-Host
}

function Get-MenuSelection {
  $Choice = Read-Host "Select an option"

  if ([string]::IsNullOrWhiteSpace($Choice)) {
    return ""
  }

  return $Choice.Trim().ToUpper()
}

function Start-MainMenu {
  while ($true) {
    Clear-Host

    Show-Banner
    Show-SystemInformation
    Show-MainMenu

    $Choice = Get-MenuSelection

    if ([string]::IsNullOrWhiteSpace($Choice)) {
      continue
    }

    switch ($Choice) {
      "1" {
        Show-ApplicationMenu
      }

      "2" {
        Show-WindowsConfigurationMenu
      }

      "3" {
        Show-DeploymentLogsMenu
      }

      "4" {
        Clear-Host

        Write-Title -Title "ABOUT"

        Write-Section -Title "Application Information"

        Write-Info -Name "Application" -Value $AppName
        Write-Info -Name "Version" -Value $AppVersion

        Pause-Application
      }

      "5" {
        Show-DeploymentValidationReport

        Pause-Application
      }

      "0" {
        Write-Host
        Write-Host "Thank you for using $AppName."
        Write-Host "Goodbye!"

        return
      }

      default {
        Write-Host
        Write-Host "Invalid selection." -ForegroundColor Red

        Pause-Application
      }
    }
  }
}