# ============================================================
# DEPLOYMENT LOGS MENU
# ============================================================

function Show-DeploymentLog {
  param(
    [Parameter(Mandatory)]
    [System.IO.FileInfo]$LogFile
  )

  Clear-Host
  Write-Title "VIEW DEPLOYMENT LOG"

  Write-Host
  Write-Host "File     : $($LogFile.Name)" -ForegroundColor Cyan
  Write-Host ("Modified : {0}" -f $LogFile.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")) -ForegroundColor DarkGray
  Write-Host
  Write-Host "------------------------------------------------------------"

  try {
    $LogContent = @(
      Get-DeploymentLogContent -LogFile $LogFile
    )

    if ($LogContent.Count -eq 0) {
      Write-Host
      Write-Host "The deployment log is empty." -ForegroundColor Yellow
    }
    else {
      foreach ($Line in $LogContent) {
        Write-Host $Line
      }
    }
  }
  catch {
    Write-Host
    Write-Host ("Unable to read the deployment log: {0}" -f $_.Exception.Message) -ForegroundColor Red
  }

  Pause-Application
}

function Show-DeploymentLogsMenu {
  $Running = $true
  
  while ($Running) {
    Clear-Host
    Write-Title "DEPLOYMENT LOGS"

    $DeploymentLogs = @(Get-DeploymentLogs -MaximumResults 10)

    if ($DeploymentLogs.Count -eq 0) {
      Write-Host
      Write-Host "No deployment logs found." -ForegroundColor Yellow
    }
    else {
      Write-Host
      Write-Section "Recent Logs"

      for (
        $Index = 0
        $Index -lt $DeploymentLogs.Count
        $Index++
      ) {
        $LogNumber = $Index + 1
        $LogFile = $DeploymentLogs[$Index]

        Write-Host (
          " {0,2}. {1}" -f $LogNumber, $LogFile.Name
        )

        Write-Host (
          "     {0} | {1:NO} bytes" -f $Logfile.LastWriteTime.ToString(
            "yyyy-MM-dd HH:mm:ss"
          ),
          $LogFile.Length
        ) -ForegroundColor DarkGray
      }
    }

    Write-Host
    Write-Host "------------------------------------------------------------"
    Write-Host "R - Refresh"
    Write-Host "O - Open Logs Folder"
    Write-Host "Q - Back"
    Write-Host

    $Choice = Read-Host "Select an option"

    switch ($Choice.Trim().ToUpper()) {
      "R" {
        continue
      }
      "O" {
        try {
          Open-DeploymentLogsFolder
        }
        catch {
          Write-Host
          Write-Host ("Unable to open the Logs folder: {0}" -f $_.Exception.Message) -ForegroundColor Red
        }
        Pause-Application
      }
      "Q" {
        $Running = $false
      }

      default {
        [int]$LogNumber = 0

        $IsNumber = [int]::TryParse(
          $Choice.Trim(),
          [ref]$LogNumber
        )

        $IsValidLogNumber = (
          $IsNumber -and
          $LogNumber -ge 1 -and
          $LogNumber -le $DeploymentLogs.Count
        )

        if ($IsValidLogNumber) {
          $SelectedLog = $DeploymentLogs[$LogNumber - 1]

          Show-DeploymentLog -LogFile $SelectedLog
        }
        else {
          Write-Host
          Write-Host "Invalid selection." -ForegroundColor Red
          Pause-Application
        }
      }
    }
  }
}