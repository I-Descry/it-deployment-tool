# ============================================================
# GUI DEPLOYMENT LOGS SCREEN
# ============================================================

function Show-GuiLogContent {
  param(
    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBox]$ContentTextBox,

    [Parameter(Mandatory)]
    [System.IO.FileInfo]$LogFile
  )

  try {
    $LogContent = @(Get-DeploymentLogContent -LogFile $LogFile)

    if ($LogContent.Count -eq 0) {
      $ContentTextBox.Text = "The deployment log is empty."
    }
    else {
      $ContentTextBox.Text = ($LogContent -join "`r`n")
    }
  }

  catch {
    $ContentTextBox.Text = "Unable to read the deployment log: $($_.Exception.Message)"
  }
}

function New-GuiLogListRow {
  param(
    [Parameter(Mandatory)]
    [System.IO.FileInfo]$LogFile
  )

  $Row = New-Object System.Windows.Controls.Border
  $Row.CornerRadius = "6"
  $Row.Padding = "10,8"
  $Row.Margin = "0,0,0,4"
  $Row.Cursor = "Hand"
  $Row.Tag = $LogFile

  $Stack = New-Object System.Windows.Controls.StackPanel
  $Row.Child = $Stack

  $NameText = New-Object System.Windows.Controls.TextBlock
  $NameText.Text = $LogFile.Name
  $NameText.FontSize = 12
  $NameText.FontWeight = "SemiBold"
  $NameText.Foreground = "#E8E9EC"
  $NameText.TextTrimming = "CharacterEllipsis"
  $Stack.Children.Add($NameText) | Out-Null

  $DetailText = New-Object System.Windows.Controls.TextBlock
  $DetailText.Text = "{0} - {1:N0} bytes" -f $LogFile.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss"), $LogFile.Length
  $DetailText.FontSize = 10.5
  $DetailText.Foreground = "#9A9EA8"
  $DetailText.Margin = "0,2,0,0"
  $Stack.Children.Add($DetailText) | Out-Null

  $Row.Add_MouseLeftButtonUp({
    try {
      foreach ($SiblingRow in $this.Parent.Children) {
        $SiblingRow.Background = $null
      }

      $this.Background = "#2438BDF8"

      Show-GuiLogContent -ContentTextBox $script:GuiLogContentTextBox -LogFile $this.Tag
    }
    catch {
      [System.Windows.MessageBox]::Show("Log view error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
  })

  return $Row
}

function Update-GuiLogsList {
  param(
    [Parameter(Mandatory)]
    [System.Windows.Controls.StackPanel]$ListPanel,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBox]$ContentTextBox
  )

  $ListPanel.Children.Clear()

  $DeploymentLogs = @(Get-DeploymentLogs -MaximumResults 10)

  if ($DeploymentLogs.Count -eq 0) {
    $ContentTextBox.Text = "No deployment logs found."
    return
  }

  foreach ($LogFile in $DeploymentLogs) {
    $Row = New-GuiLogListRow -LogFile $LogFile
    $ListPanel.Children.Add($Row) | Out-Null
  }

  $ListPanel.Children[0].Background = "#2438BDF8"
  Show-GuiLogContent -ContentTextBox $ContentTextBox -LogFile $DeploymentLogs[0]
}
