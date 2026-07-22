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

  $script:ApplicationMap = @{}

  foreach ($Group in $GroupedApplications) {
    Write-Host
    Write-Section $Group.$Name

    foreach ($Application in $Group.Group) {
      $script:ApplicationMap[$ApplicationNumber] = $Application
      $Checkbox = if ($Application.Selected) {
        "[X]"
      }
      else {
        "[ ]"
      }

      $InstallationStatus = if ($Application.Installed) {
        "[Installed]"
      }
      else {
        "[Not Installed]"
      }

      $RecommendedStatus = if (
        $Application.Recommended -eq $true
      ) {
        "[Recommended]"
      }
      else {
        ""
      }

      $StatusText = ($InstallationStatus, $RecommendedStatus | Where-Object {
        -not [string]::IsNullOrWhiteSpace($_)
      }
      ) -join " "

      Write-Host (
        " {0,2}. {1} {2,-34} {3}" -f $ApplicationNumber, $CheckBox, $Application.Name, $StatusText
      )

      $ApplicationNumber++
    }
  }

  $SelectedCount = @($script:Applications | Where-Object {
    $_.Selected -eq $true
  }
  ).Count

  Write-Host
  Write-Host ("Selected applications: {0}" -f $SelectedCount) -ForegroundColor Cyan
}

function Show-ApplicationOptions {

  Write-Host
  Write-Host "------------------------------------------------------------"

  Write-Host "[A] - Select All"
  Write-Host "[R] - Select Recommended"
  Write-Host "[C] - Clear All"
  Write-Host "[I] - Preview and Install Selected"
  Write-Host "[Q] - Back"
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

      "R" {
        $RecommendedCount = Select-RecommendedApplications

        Write-DeploymentLog -Level "INFO" -Message ("{0} recommended application(s) selected." -f $RecommendedCount)

        return $true
      }

      "C" {
        Clear-AllApplications

        return $true
      }

      "I" {
        $InstallationStarted = Start-SelectedApplicationsSetup

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