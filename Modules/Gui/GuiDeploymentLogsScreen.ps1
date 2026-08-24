# ============================================================
# GUI DEPLOYMENT LOGS SCREEN
# ============================================================

function Show-GuiLogContent {
  param(
    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBox]$ContentTextBox,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$NameText,

    [Parameter(Mandatory)]
    [System.IO.FileInfo]$LogFile
  )

  $NameText.Text = $LogFile.Name

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
  $Row.Background = "Transparent"
  $Row.Tag = $LogFile

  $OuterPanel = New-Object System.Windows.Controls.StackPanel
  $OuterPanel.Orientation = "Horizontal"
  $Row.Child = $OuterPanel

  $Icon = New-Object System.Windows.Controls.Canvas
  $Icon.Width = 14
  $Icon.Height = 14
  $Icon.Margin = "0,1,8,0"
  $Icon.VerticalAlignment = "Top"
  $IconRect = New-GuiIconShape -Type Rectangle -Color "#9A9EA8" -StrokeThickness 1.2 -X 3 -Y 1 -Width 8 -Height 12 -RadiusX 1
  $IconLine1 = New-GuiIconShape -Type Line -Color "#9A9EA8" -StrokeThickness 1.1 -X1 5.2 -Y1 4.5 -X2 8.8 -Y2 4.5
  $IconLine2 = New-GuiIconShape -Type Line -Color "#9A9EA8" -StrokeThickness 1.1 -X1 5.2 -Y1 7 -X2 8.8 -Y2 7
  $Icon.Children.Add($IconRect) | Out-Null
  $Icon.Children.Add($IconLine1) | Out-Null
  $Icon.Children.Add($IconLine2) | Out-Null
  $OuterPanel.Children.Add($Icon) | Out-Null

  $Stack = New-Object System.Windows.Controls.StackPanel
  $OuterPanel.Children.Add($Stack) | Out-Null

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
        $SiblingRow.Background = "Transparent"
      }

      $this.Background = "#2438BDF8"

      Show-GuiLogContent -ContentTextBox $script:GuiLogContentTextBox -NameText $script:GuiSelectedLogNameText -LogFile $this.Tag
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
    [System.Windows.Controls.TextBox]$ContentTextBox,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$NameText
  )

  $ListPanel.Children.Clear()

  $DeploymentLogs = @(Get-DeploymentLogs -MaximumResults 10)

  if ($DeploymentLogs.Count -eq 0) {
    $NameText.Text = "-"
    $ContentTextBox.Text = "No deployment logs found."
    return
  }

  foreach ($LogFile in $DeploymentLogs) {
    $Row = New-GuiLogListRow -LogFile $LogFile
    $ListPanel.Children.Add($Row) | Out-Null
  }

  $ListPanel.Children[0].Background = "#2438BDF8"
  Show-GuiLogContent -ContentTextBox $ContentTextBox -NameText $NameText -LogFile $DeploymentLogs[0]
}
