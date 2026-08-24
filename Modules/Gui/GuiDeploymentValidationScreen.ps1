# ============================================================
# GUI DEPLOYMENT VALIDATION SCREEN
# ============================================================
# New-GuiValidationStatusRow is also reused by GuiWindowsConfigScreen.ps1
# for the local standard users list, so this file must load before it.

function New-GuiValidationStatusRow {
  param(
    [Parameter(Mandatory)]
    [string]$StatusLabel,

    [Parameter(Mandatory)]
    [bool]$Passed,

    [Parameter(Mandatory)]
    [string]$PrimaryText,

    [Parameter(Mandatory)]
    [string]$DetailText
  )

  $RowGrid = New-Object System.Windows.Controls.Grid
  $RowGrid.Margin = "0,4,0,4"

  $StatusColumn = New-Object System.Windows.Controls.ColumnDefinition
  $StatusColumn.Width = "56"
  $RowGrid.ColumnDefinitions.Add($StatusColumn)

  $NameColumn = New-Object System.Windows.Controls.ColumnDefinition
  $NameColumn.Width = "220"
  $RowGrid.ColumnDefinitions.Add($NameColumn)

  $DetailColumn = New-Object System.Windows.Controls.ColumnDefinition
  $DetailColumn.Width = "*"
  $RowGrid.ColumnDefinitions.Add($DetailColumn)

  $StatusText = New-Object System.Windows.Controls.TextBlock
  $StatusText.Text = $StatusLabel
  $StatusText.FontSize = 11
  $StatusText.FontWeight = "Bold"
  $StatusText.Foreground = if ($Passed) { "#34D399" } else { "#F2555A" }
  [System.Windows.Controls.Grid]::SetColumn($StatusText, 0)
  $RowGrid.Children.Add($StatusText) | Out-Null

  $NameText = New-Object System.Windows.Controls.TextBlock
  $NameText.Text = $PrimaryText
  $NameText.FontSize = 12.5
  $NameText.FontWeight = "SemiBold"
  $NameText.Foreground = "#E8E9EC"
  $NameText.TextTrimming = "CharacterEllipsis"
  $NameText.Margin = "0,0,10,0"
  [System.Windows.Controls.Grid]::SetColumn($NameText, 1)
  $RowGrid.Children.Add($NameText) | Out-Null

  $DetailTextBlock = New-Object System.Windows.Controls.TextBlock
  $DetailTextBlock.Text = $DetailText
  $DetailTextBlock.FontSize = 11.5
  $DetailTextBlock.Foreground = "#9A9EA8"
  $DetailTextBlock.TextWrapping = "Wrap"
  [System.Windows.Controls.Grid]::SetColumn($DetailTextBlock, 2)
  $RowGrid.Children.Add($DetailTextBlock) | Out-Null

  return $RowGrid
}

function New-GuiDeviceReadinessRow {
  param(
    [Parameter(Mandatory)]
    [PSCustomObject]$Result
  )

  $StatusLabel = if ($Result.Passed) { "PASS" } else { "FAIL" }

  return New-GuiValidationStatusRow -StatusLabel $StatusLabel -Passed $Result.Passed -PrimaryText $Result.Name -DetailText $Result.Detail
}

function New-GuiInstallerReadinessRow {
  param(
    [Parameter(Mandatory)]
    [PSCustomObject]$Result
  )

  $Passed = ($Result.Status -eq "READY")
  $Detail = "{0} - {1}" -f $Result.InstallType, $Result.Message

  return New-GuiValidationStatusRow -StatusLabel $Result.Status -Passed $Passed -PrimaryText $Result.Name -DetailText $Detail
}

function New-GuiValidationSectionCard {
  param(
    [Parameter(Mandatory)]
    [string]$SectionTitle,

    [Parameter(Mandatory)]
    [System.Windows.UIElement[]]$Rows,

    [Parameter(Mandatory)]
    [int]$PassedCount,

    [Parameter(Mandatory)]
    [int]$TotalCount
  )

  $Card = New-Object System.Windows.Controls.Border
  $Card.Background = "#1C1F26"
  $Card.BorderBrush = "#2C2F38"
  $Card.BorderThickness = "1"
  $Card.CornerRadius = "10"
  $Card.Padding = "18"
  $Card.Margin = "0,0,0,16"

  $Stack = New-Object System.Windows.Controls.StackPanel
  $Card.Child = $Stack

  $HeaderGrid = New-Object System.Windows.Controls.Grid
  $HeaderGrid.Margin = "0,0,0,10"

  $TitleColumn = New-Object System.Windows.Controls.ColumnDefinition
  $TitleColumn.Width = "*"
  $HeaderGrid.ColumnDefinitions.Add($TitleColumn)

  $CountColumn = New-Object System.Windows.Controls.ColumnDefinition
  $CountColumn.Width = "Auto"
  $HeaderGrid.ColumnDefinitions.Add($CountColumn)

  $Header = New-Object System.Windows.Controls.TextBlock
  $Header.Text = $SectionTitle.ToUpper()
  $Header.FontSize = 12
  $Header.FontWeight = "Bold"
  $Header.Foreground = "#9A9EA8"
  [System.Windows.Controls.Grid]::SetColumn($Header, 0)
  $HeaderGrid.Children.Add($Header) | Out-Null

  $CountText = New-Object System.Windows.Controls.TextBlock
  $CountText.Text = "$PassedCount / $TotalCount passed"
  $CountText.FontSize = 11
  $CountText.FontWeight = "SemiBold"
  $CountText.Foreground = if ($PassedCount -eq $TotalCount) { "#34D399" } else { "#F2555A" }
  [System.Windows.Controls.Grid]::SetColumn($CountText, 1)
  $HeaderGrid.Children.Add($CountText) | Out-Null

  $Stack.Children.Add($HeaderGrid) | Out-Null

  foreach ($Row in $Rows) {
    $Stack.Children.Add($Row) | Out-Null
  }

  return $Card
}

function Invoke-GuiDeploymentValidation {
  param(
    [Parameter(Mandatory)]
    [System.Windows.Controls.StackPanel]$ValidationPanel,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$SummaryText
  )

  $ValidationPanel.Children.Clear()

  $DeviceResults = @(Get-DeploymentValidationResults)
  Write-DeploymentValidationResultsToLog -Results $DeviceResults

  $DevicePassedCount = @($DeviceResults | Where-Object { $_.Passed }).Count
  $DeviceRows = @($DeviceResults | ForEach-Object { New-GuiDeviceReadinessRow -Result $_ })
  $DeviceCard = New-GuiValidationSectionCard -SectionTitle "Device Readiness Checks" -Rows $DeviceRows -PassedCount $DevicePassedCount -TotalCount $DeviceResults.Count
  $ValidationPanel.Children.Add($DeviceCard) | Out-Null

  $ReadinessResults = @(Get-InstallerPackageReadiness -Applications $script:Applications)
  $ReadinessPassedCount = @($ReadinessResults | Where-Object { $_.Status -eq "READY" }).Count
  $ReadinessRows = @($ReadinessResults | ForEach-Object { New-GuiInstallerReadinessRow -Result $_ })
  $ReadinessCard = New-GuiValidationSectionCard -SectionTitle "Installer Package Status" -Rows $ReadinessRows -PassedCount $ReadinessPassedCount -TotalCount $ReadinessResults.Count
  $ValidationPanel.Children.Add($ReadinessCard) | Out-Null

  $TotalPassed = $DevicePassedCount + $ReadinessPassedCount
  $TotalChecks = $DeviceResults.Count + $ReadinessResults.Count
  $TotalFailed = $TotalChecks - $TotalPassed

  $SummaryText.Text = "$TotalPassed passed, $TotalFailed failed"
  $SummaryText.Foreground = if ($TotalFailed -eq 0) { "#34D399" } else { "#F2555A" }
}
