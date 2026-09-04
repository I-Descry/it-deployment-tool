function Write-Line {
  Write-Host "============================================================" -ForegroundColor Cyan
}

function Write-Section {
  param(
      [string]$Title
  )

  Write-Host ""
  Write-Host $Title -ForegroundColor Yellow
  Write-Host "------------------------------------------------------------"
}

function Write-Status {
  param(
    [string]$Name,
    [bool]$Status
  )

  Write-Host ("{0,-16}: " -f $Name) -NoNewline

  if ($Status) {
    Write-Host "[ OK ]" -ForegroundColor Green
  }
  else {
    Write-Host "[ FAIL ]" -ForegroundColor Red
  }
}

function Write-Info {
  param(
    [string]$Name,
    [string]$Value  
  )

  Write-Host ("{0,-16}: {1}" -f $Name, $Value)
}

function Pause-Application {
  Write-Host
  [void](Read-Host "Press ENTER to continue")
}

function Show-Banner {

    Clear-Host

    Write-Line
    Write-Host 
    Write-Host "                   $AppName" -ForegroundColor Cyan
    Write-Host "                     Version $AppVersion" -ForegroundColor DarkGray
    Write-Host 
    Write-Line
    Write-Host 
}

function Write-Title {
  param(
    [string]$Title
  )

  $LineWidth = 60

  $LeftPadding = [Math]::Max(
    0,
    [Math]::Floor(
      ($LineWidth - $Title.Length) / 2
    )
  )

  Write-Line

  Write-Host ((" " * $LeftPadding) + $Title) -ForegroundColor Cyan

  Write-Line
}

function Read-DeploymentMode {
  # Sets $script:DeploymentMode (ApplicationCatalog.ps1), read by Get-VisibleApplications and Show-MainMenu -- IT is unchanged, Employee restricts the Applications catalog and hides most menu options.
  Write-Title -Title "SELECT DEPLOYMENT MODE"

  while ($true) {
    Write-Host " [1] IT       - All features and application categories."
    Write-Host " [2] Employee - Applications only (Browsers, Communication, Remote Support, Company Apps, Productivity, Printers)."
    Write-Host

    $Choice = Read-Host "Select an option"

    switch ([string]$Choice.Trim()) {
      "1" {
        $script:DeploymentMode = "IT"
        return
      }
      "2" {
        $script:DeploymentMode = "Employee"
        return
      }
      default {
        Write-Host
        Write-Host "Invalid selection." -ForegroundColor Red
        Write-Host
      }
    }
  }
}