function Show-MainMenu {
  Write-Host ""
  Write-Host "============================================================" -ForegroundColor Cyan
  Write-Host "MAIN MENU" -ForegroundColor Yellow
  Write-Host "============================================================" -ForegroundColor Cyan

  Write-Host "[1] Install Applications"
  Write-Host "[2] Configure Windows"
  Write-Host "[3] Deployment Logs"
  Write-Host "[4] About"
  Write-Host ""
  Write-Host "[0] Exit"

  Write-Host ""
}

function Get-MenuSelection {
  $choice = Read-Host "Select an option"
  return $choice
}

function Start-MainMenu {
  do {
    Show-MainMenu
    $choice = Get-MenuSelection
    switch ($choice) {
      "1" {
        Show-ApplicationMenu
      }
      "2" {
        Write-Host ""
        Write-Host "Opening Windows Configuration..."
        Pause-Application
      }
      "3" {
        Write-Host ""
        Write-Host "Opening Deployment Logs..."
        Pause-Application
      }
      "4" {
        Write-Host ""
        Write-Host "IT DEPLOYMENT TOOL"
        Write-Host "Version $AppVersion"
        Pause-Application
      }
      "0" {
        Write-Host ""
        Write-Host "Thank you for using $AppName."
        Write-Host "Goodbye!"
      }
      default {
        Write-Host ""
        Write-Host "Invalid selection." -ForegroundColor Red
        Pause-Application
      }
    }
  } while ($choice -ne "0")
}