# ============================================================
# GUI WINDOW (Phase A - real catalog data)
# ============================================================

function New-GuiApplicationRow {
  param(
    [Parameter(Mandatory)]
    [PSCustomObject]$Application
  )

  $RowGrid = New-Object System.Windows.Controls.Grid
  $RowGrid.Margin = "0,3,0,3"

  $NameColumn = New-Object System.Windows.Controls.ColumnDefinition
  $NameColumn.Width = "*"
  $RowGrid.ColumnDefinitions.Add($NameColumn)

  $RecommendedColumn = New-Object System.Windows.Controls.ColumnDefinition
  $RecommendedColumn.Width = "Auto"
  $RowGrid.ColumnDefinitions.Add($RecommendedColumn)

  $StatusColumn = New-Object System.Windows.Controls.ColumnDefinition
  $StatusColumn.Width = "Auto"
  $RowGrid.ColumnDefinitions.Add($StatusColumn)

  $NameText = New-Object System.Windows.Controls.TextBlock
  $NameText.Text = $Application.Name
  $NameText.TextTrimming = "CharacterEllipsis"

  $CheckBox = New-Object System.Windows.Controls.CheckBox
  $CheckBox.Content = $NameText
  $CheckBox.IsChecked = [bool]$Application.Selected
  $CheckBox.Foreground = "#E8E9EC"
  $CheckBox.FontSize = 12.5
  $CheckBox.VerticalContentAlignment = "Center"
  $CheckBox.Tag = $Application
  $CheckBox.Add_Click({
    $this.Tag.Selected = [bool]$this.IsChecked
  })
  [System.Windows.Controls.Grid]::SetColumn($CheckBox, 0)
  $RowGrid.Children.Add($CheckBox) | Out-Null

  if ($Application.Recommended -eq $true) {
    $RecommendedText = New-Object System.Windows.Controls.TextBlock
    $RecommendedText.Text = "Recommended"
    $RecommendedText.FontSize = 9.5
    $RecommendedText.FontWeight = "Bold"
    $RecommendedText.Foreground = "#FBBF24"
    $RecommendedText.VerticalAlignment = "Center"
    $RecommendedText.Margin = "8,0,0,0"
    [System.Windows.Controls.Grid]::SetColumn($RecommendedText, 1)
    $RowGrid.Children.Add($RecommendedText) | Out-Null
  }

  $StatusText = New-Object System.Windows.Controls.TextBlock
  $StatusText.Text = if ($Application.Installed) { "Installed" } else { "Not Installed" }
  $StatusText.FontSize = 10.5
  $StatusText.FontWeight = "SemiBold"
  $StatusText.Foreground = if ($Application.Installed) { "#34D399" } else { "#6B6F79" }
  $StatusText.VerticalAlignment = "Center"
  $StatusText.Margin = "8,0,0,0"
  [System.Windows.Controls.Grid]::SetColumn($StatusText, 2)
  $RowGrid.Children.Add($StatusText) | Out-Null

  return $RowGrid
}

function New-GuiCategoryCard {
  param(
    [Parameter(Mandatory)]
    [string]$CategoryName,

    [Parameter(Mandatory)]
    [object[]]$Applications
  )

  $Card = New-Object System.Windows.Controls.Border
  $Card.Background = "#1C1F26"
  $Card.BorderBrush = "#2C2F38"
  $Card.BorderThickness = "1"
  $Card.CornerRadius = "10"
  $Card.Padding = "14"
  $Card.Width = 360
  $Card.Margin = "0,0,14,14"

  $Stack = New-Object System.Windows.Controls.StackPanel
  $Card.Child = $Stack

  $Header = New-Object System.Windows.Controls.TextBlock
  $Header.Text = $CategoryName.ToUpper()
  $Header.FontSize = 11
  $Header.FontWeight = "Bold"
  $Header.Foreground = "#9A9EA8"
  $Header.Margin = "0,0,0,8"
  $Stack.Children.Add($Header) | Out-Null

  foreach ($Application in $Applications) {
    $Row = New-GuiApplicationRow -Application $Application
    $Stack.Children.Add($Row) | Out-Null
  }

  return $Card
}

function Update-GuiApplicationGrid {
  param(
    [Parameter(Mandatory)]
    [System.Windows.Controls.ItemsControl]$GridPanel
  )

  $GridPanel.Items.Clear()

  $Grouped = $script:Applications | Group-Object Category

  foreach ($Group in $Grouped) {
    $Card = New-GuiCategoryCard -CategoryName $Group.Name -Applications $Group.Group
    $GridPanel.Items.Add($Card) | Out-Null
  }
}

function Update-GuiSelectedCount {
  param(
    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$CountText
  )

  $SelectedCount = @($script:Applications | Where-Object { $_.Selected -eq $true }).Count
  $CountText.Text = "$SelectedCount selected"
}

function Switch-GuiScreen {
  param(
    [Parameter(Mandatory)]
    [string]$ScreenName,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Border]$ActiveBorder,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$ActiveText
  )

  foreach ($NavBorder in $script:GuiNavBorders) {
    $NavBorder.Background = $null
  }

  foreach ($NavText in $script:GuiNavTexts) {
    $NavText.Foreground = "#9A9EA8"
    $NavText.FontWeight = "Normal"
  }

  $ActiveBorder.Background = "#2438BDF8"
  $ActiveText.Foreground = "#38BDF8"
  $ActiveText.FontWeight = "SemiBold"

  if ($ScreenName -eq "Applications") {
    $script:GuiApplicationsToolbar.Visibility = "Visible"
    $script:GuiApplicationsScrollViewer.Visibility = "Visible"
    $script:GuiPlaceholderText.Visibility = "Collapsed"
  }
  else {
    $script:GuiApplicationsToolbar.Visibility = "Collapsed"
    $script:GuiApplicationsScrollViewer.Visibility = "Collapsed"
    $script:GuiPlaceholderText.Text = "$ScreenName screen - not built yet"
    $script:GuiPlaceholderText.Visibility = "Visible"
  }
}

function Update-GuiSystemInfoBar {
  param(
    [Parameter(Mandatory)]
    [System.Windows.Window]$Window
  )

  Get-SystemInformation
  Test-Administrator -PassThru | Out-Null
  Test-Internet -PassThru | Out-Null
  Test-Winget -PassThru | Out-Null

  $Window.FindName("ComputerNameText").Text = $SystemInfo.ComputerName
  $Window.FindName("UserNameText").Text = $SystemInfo.LoggedUser
  $Window.FindName("ModelText").Text = $SystemInfo.Model

  $AdminStatusText = $Window.FindName("AdminStatusText")
  $AdminStatusText.Foreground = if ($SystemInfo.IsAdministrator) { "#34D399" } else { "#F2555A" }

  $InternetStatusText = $Window.FindName("InternetStatusText")
  $InternetStatusText.Foreground = if ($SystemInfo.InternetStatus) { "#34D399" } else { "#F2555A" }

  $WingetStatusText = $Window.FindName("WingetStatusText")
  $WingetStatusText.Foreground = if ($SystemInfo.WingetAvailable) { "#34D399" } else { "#F2555A" }
}

function Show-MainWindow {
  Add-Type -AssemblyName PresentationFramework

  Initialize-Applications | Out-Null
  Update-ApplicationInstallationStatus

  $XamlPath = Join-Path $script:ITDeploymentToolRoot "Modules\Gui\MainWindow.xaml"

  [xml]$WindowXaml = Get-Content -LiteralPath $XamlPath -Raw

  $Reader = New-Object System.Xml.XmlNodeReader $WindowXaml
  $Window = [Windows.Markup.XamlReader]::Load($Reader)

  $AppGridPanel = $Window.FindName("AppGridPanel")
  $SelectedCountText = $Window.FindName("SelectedCountText")
  $SelectAllButton = $Window.FindName("SelectAllButton")
  $SelectRecommendedButton = $Window.FindName("SelectRecommendedButton")
  $ClearAllButton = $Window.FindName("ClearAllButton")

  Update-GuiApplicationGrid -GridPanel $AppGridPanel
  Update-GuiSelectedCount -CountText $SelectedCountText
  Update-GuiSystemInfoBar -Window $Window

  $SelectAllButton.Add_Click({
    try {
      Select-AllApplications
      Update-GuiApplicationGrid -GridPanel $AppGridPanel
      Update-GuiSelectedCount -CountText $SelectedCountText
    }
    catch {
      [System.Windows.MessageBox]::Show("Select All error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
  })

  $SelectRecommendedButton.Add_Click({
    try {
      Select-RecommendedApplications | Out-Null
      Update-GuiApplicationGrid -GridPanel $AppGridPanel
      Update-GuiSelectedCount -CountText $SelectedCountText
    }
    catch {
      [System.Windows.MessageBox]::Show("Select Recommended error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
  })

  $ClearAllButton.Add_Click({
    try {
      Clear-AllApplications
      Update-GuiApplicationGrid -GridPanel $AppGridPanel
      Update-GuiSelectedCount -CountText $SelectedCountText
    }
    catch {
      [System.Windows.MessageBox]::Show("Clear All error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
  })

  $NavApplications = $Window.FindName("NavApplications")
  $NavApplicationsText = $Window.FindName("NavApplicationsText")
  $NavWindowsConfig = $Window.FindName("NavWindowsConfig")
  $NavWindowsConfigText = $Window.FindName("NavWindowsConfigText")
  $NavDeploymentLogs = $Window.FindName("NavDeploymentLogs")
  $NavDeploymentLogsText = $Window.FindName("NavDeploymentLogsText")
  $NavDeploymentValidation = $Window.FindName("NavDeploymentValidation")
  $NavDeploymentValidationText = $Window.FindName("NavDeploymentValidationText")

  $script:GuiNavBorders = @($NavApplications, $NavWindowsConfig, $NavDeploymentLogs, $NavDeploymentValidation)
  $script:GuiNavTexts = @($NavApplicationsText, $NavWindowsConfigText, $NavDeploymentLogsText, $NavDeploymentValidationText)
  $script:GuiApplicationsToolbar = $Window.FindName("ApplicationsToolbar")
  $script:GuiApplicationsScrollViewer = $Window.FindName("ApplicationsScrollViewer")
  $script:GuiPlaceholderText = $Window.FindName("PlaceholderText")

  $NavApplications.Add_MouseLeftButtonUp({
    try {
      Switch-GuiScreen -ScreenName "Applications" -ActiveBorder $NavApplications -ActiveText $NavApplicationsText
    }
    catch {
      [System.Windows.MessageBox]::Show("Navigation error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
  })

  $NavWindowsConfig.Add_MouseLeftButtonUp({
    try {
      Switch-GuiScreen -ScreenName "Windows Configuration" -ActiveBorder $NavWindowsConfig -ActiveText $NavWindowsConfigText
    }
    catch {
      [System.Windows.MessageBox]::Show("Navigation error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
  })

  $NavDeploymentLogs.Add_MouseLeftButtonUp({
    try {
      Switch-GuiScreen -ScreenName "Deployment Logs" -ActiveBorder $NavDeploymentLogs -ActiveText $NavDeploymentLogsText
    }
    catch {
      [System.Windows.MessageBox]::Show("Navigation error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
  })

  $NavDeploymentValidation.Add_MouseLeftButtonUp({
    try {
      Switch-GuiScreen -ScreenName "Deployment Validation" -ActiveBorder $NavDeploymentValidation -ActiveText $NavDeploymentValidationText
    }
    catch {
      [System.Windows.MessageBox]::Show("Navigation error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
  })

  [void]$Window.ShowDialog()
}
