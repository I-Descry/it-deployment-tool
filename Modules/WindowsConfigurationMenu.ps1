# ============================================================
# WINDOWS CONFIGURATION MENU
# ============================================================

function Show-WindowsConfigurationMenu {
  while ($true) {
    Clear-Host

    Write-Title -Title "CONFIGURE WINDOWS"

    Write-Section -Title "Windows Configuration Options"

    Write-Host " [1] Rename Computer"
    Write-Host " [2] Create Local Standard User"
    Write-Host " [3] Configure Power and Sleep Settings"
    Write-Host " [4] View Current Windows Configuration"
    Write-Host
    Write-Host " [Q] Back to Main Menu"

    Write-Host
    Write-Host "------------------------------------------------------------"

    $Selection = Read-Host "Select an option"

    switch ($Selection.Trim().ToUpper()) {
      "1" {
        Start-ComputerRenameWizard
      }

      "2" {
        Start-LocalStandardUserWizard
      }

      "3" {
        $null = Start-PowerConfigurationWizard
      }

      "4" {
        Show-WindowsConfigurationReport

        Pause-Application
      }

      "Q" {
        return
      }

      default {
        Write-Host
        Write-Host "Invalid selection. Please try again." -ForegroundColor Red

        Start-Sleep -Seconds 1
      }
    }
  }
}