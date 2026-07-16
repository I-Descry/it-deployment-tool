# ============================================================
# APPLICATION MENU
# ============================================================

function Show-ApplicationMenu {

    $Running = $true

    while ($Running) {

        Clear-Host

        Write-Title "INSTALL APPLICATIONS"

        Show-ApplicationList

        Show-ApplicationOptions

        $Choice = Read-ApplicationChoice

        $Running = Process-ApplicationChoice -Choice $Choice
    }
}

function Show-ApplicationList {

  $GroupedApplications = $script:Applications | Group-Object Category

  $ApplicationNumber = 1

  # Rebuild the number-to-application lookup every time the menu is displayed
  $script:ApplicationMap = @{}

  foreach ($Group in $GroupedApplications) {

    Write-Host
    Write-Section $Group.Name
    
    foreach ($Application in $Group.Group) {

      $script:ApplicationMap[$ApplicationNumber] = $Application
      $CheckBox = if ($Application.Selected) {
        "[X]"
      }
      else {
        "[ ]"
      }

      Write-Host (" {0,2}. {1} {2}" -f $ApplicationNumber, $CheckBox, $Application.Name)
      $ApplicationNumber++
    }
  }
}

function Show-ApplicationOptions {

  Write-Host
  Write-Host "------------------------------------------------------------"

  Write-Host "A - Select All"
  Write-Host "C - Clear All"
  Write-Host "I - Install Selected"
  Write-Host "Q - Back"
}

function Read-ApplicationChoice {

  Write-Host
  return (Read-Host "Select an option")
}

function Process-ApplicationChoice {

  param(
    [string]$Choice
  )

    $NormalizedChoice = $Choice.Trim().ToUpper()

    switch ($NormalizedChoice) {

      "Q" {
        return $false
      }

      "A" {
        Select-AllApplications

        return $true
      }

      "C" {
        Clear-AllApplications

        return $true
      }

      "I" {
        Install-SelectedApplications

        return $true
      }

      default {

        $ApplicationNumber = 0

        $IsNumber = [int]::TryParse($NormalizedChoice,[ref]$ApplicationNumber)

        if ($IsNumber) {

          $WasToggled = Toggle-ApplicationSelection -Number $ApplicationNumber

            if (-not $WasToggled) {
              Write-Host
              Write-Host ("No application exists with number {0}." -f $ApplicationNumber) -ForegroundColor Red

              Pause-Application
            }
          return $true
        }

      Write-Host
      Write-Host "Invalid selection." -ForegroundColor Red
      Pause-Application

      return $true
    }
  }
}