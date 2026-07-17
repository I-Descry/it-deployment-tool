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

  Write-Host("{0,-14}: " -f $Name) -NoNewline
  
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

  Write-Line
  Write-Host ("{0,30}" -f $Title) -ForegroundColor Cyan
  Write-Line
}