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
    $script:GuiDeploymentValidationToolbar.Visibility = "Collapsed"
    $script:GuiDeploymentValidationScrollViewer.Visibility = "Collapsed"
    $script:GuiDeploymentLogsToolbar.Visibility = "Collapsed"
    $script:GuiDeploymentLogsContent.Visibility = "Collapsed"
    $script:GuiWindowsConfigToolbar.Visibility = "Collapsed"
    $script:GuiWindowsConfigScrollViewer.Visibility = "Collapsed"
    $script:GuiPlaceholderText.Visibility = "Collapsed"
  }
  elseif ($ScreenName -eq "Deployment Validation") {
    $script:GuiApplicationsToolbar.Visibility = "Collapsed"
    $script:GuiApplicationsScrollViewer.Visibility = "Collapsed"
    $script:GuiDeploymentValidationToolbar.Visibility = "Visible"
    $script:GuiDeploymentValidationScrollViewer.Visibility = "Visible"
    $script:GuiDeploymentLogsToolbar.Visibility = "Collapsed"
    $script:GuiDeploymentLogsContent.Visibility = "Collapsed"
    $script:GuiWindowsConfigToolbar.Visibility = "Collapsed"
    $script:GuiWindowsConfigScrollViewer.Visibility = "Collapsed"
    $script:GuiPlaceholderText.Visibility = "Collapsed"

    Invoke-GuiDeploymentValidation -ValidationPanel $script:GuiDeploymentValidationPanel -SummaryText $script:GuiValidationSummaryText
  }
  elseif ($ScreenName -eq "Deployment Logs") {
    $script:GuiApplicationsToolbar.Visibility = "Collapsed"
    $script:GuiApplicationsScrollViewer.Visibility = "Collapsed"
    $script:GuiDeploymentValidationToolbar.Visibility = "Collapsed"
    $script:GuiDeploymentValidationScrollViewer.Visibility = "Collapsed"
    $script:GuiDeploymentLogsToolbar.Visibility = "Visible"
    $script:GuiDeploymentLogsContent.Visibility = "Visible"
    $script:GuiWindowsConfigToolbar.Visibility = "Collapsed"
    $script:GuiWindowsConfigScrollViewer.Visibility = "Collapsed"
    $script:GuiPlaceholderText.Visibility = "Collapsed"

    Update-GuiLogsList -ListPanel $script:GuiDeploymentLogsPanel -ContentTextBox $script:GuiLogContentTextBox
  }
  elseif ($ScreenName -eq "Windows Configuration") {
    $script:GuiApplicationsToolbar.Visibility = "Collapsed"
    $script:GuiApplicationsScrollViewer.Visibility = "Collapsed"
    $script:GuiDeploymentValidationToolbar.Visibility = "Collapsed"
    $script:GuiDeploymentValidationScrollViewer.Visibility = "Collapsed"
    $script:GuiDeploymentLogsToolbar.Visibility = "Collapsed"
    $script:GuiDeploymentLogsContent.Visibility = "Collapsed"
    $script:GuiWindowsConfigToolbar.Visibility = "Visible"
    $script:GuiWindowsConfigScrollViewer.Visibility = "Visible"
    $script:GuiPlaceholderText.Visibility = "Collapsed"

    Invoke-GuiWindowsConfigurationRefresh -DeviceFields $script:GuiWindowsConfigDeviceFields -CurrentNameText $script:GuiCurrentComputerNameText -LocalUsersListPanel $script:GuiLocalUsersListPanel -CurrentPluggedInText $script:GuiCurrentPluggedInText -CurrentBatteryText $script:GuiCurrentBatteryText
  }
  else {
    $script:GuiApplicationsToolbar.Visibility = "Collapsed"
    $script:GuiApplicationsScrollViewer.Visibility = "Collapsed"
    $script:GuiDeploymentValidationToolbar.Visibility = "Collapsed"
    $script:GuiDeploymentValidationScrollViewer.Visibility = "Collapsed"
    $script:GuiDeploymentLogsToolbar.Visibility = "Collapsed"
    $script:GuiDeploymentLogsContent.Visibility = "Collapsed"
    $script:GuiWindowsConfigToolbar.Visibility = "Collapsed"
    $script:GuiWindowsConfigScrollViewer.Visibility = "Collapsed"
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

function Start-GuiApplicationQueue {
  param(
    [Parameter(Mandatory)]
    [ValidateSet("Install", "Uninstall")]
    [string]$Mode,

    [Parameter(Mandatory)]
    [AllowEmptyCollection()]
    [PSCustomObject[]]$Applications,

    [int]$PreSkippedCount = 0,

    [string[]]$PreFailureMessages = @(),

    [Parameter(Mandatory)]
    [System.Windows.Controls.ItemsControl]$GridPanel,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$CountText,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Button[]]$ButtonsToDisable
  )

  if (($Applications.Count -eq 0) -and ($PreSkippedCount -eq 0)) {
    return
  }

  foreach ($Button in $ButtonsToDisable) {
    $Button.IsEnabled = $false
  }

  $script:GuiQueueRunning = $true
  $CountText.Text = if ($Mode -eq "Install") { "Installing..." } else { "Uninstalling..." }

  $RootPath = $script:ITDeploymentToolRoot
  $LogPath = $script:LogFilePath
  $ProgressQueue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()

  # Deliberately duplicated from Start.ps1's $ModulePaths rather than reused --
  # this is the minimal subset the install/uninstall call graph actually
  # touches, re-loaded fresh inside a background runspace that starts with no
  # session state of its own. Keep in sync if a new install type module is
  # ever added to the router.
  $BackgroundScript = {
    param(
      [string]$RootPath,
      [string]$LogPath,
      [string]$Mode,
      [object[]]$Applications,
      [System.Collections.Concurrent.ConcurrentQueue[string]]$ProgressQueue
    )

    $ModulePaths = @(
      "Core\Logging.ps1"
      "Applications\InstalledApplications.ps1"
      "Applications\ApplicationProcessCheck.ps1"
      "Applications\MicrosoftTeams.ps1"
      "Installation\InstallationResult.ps1"
      "Installation\UninstallationResult.ps1"
      "Installation\WingetInstaller.ps1"
      "Installation\OfflineInstaller.ps1"
      "Installation\MsiInstaller.ps1"
      "Installation\AppxInstaller.ps1"
      "Installation\ScriptInstaller.ps1"
      "Installation\ZipInstaller.ps1"
      "Installation\CrowdStrikeInstaller.ps1"
      "Installation\OfficeIsoInstaller.ps1"
      "Installation\Office2021ImgInstaller.ps1"
      "Installation\InstallationRouter.ps1"
      "Installation\UninstallationRouter.ps1"
    )

    foreach ($ModulePath in $ModulePaths) {
      . (Join-Path $RootPath "Modules\$ModulePath")
    }

    # Must happen AFTER dot-sourcing: Core\Logging.ps1's own top-level code
    # resets $script:LogFilePath to $null when it loads, which would silently
    # undo this assignment if it ran first.
    $script:ITDeploymentToolRoot = $RootPath
    $script:LogFilePath = $LogPath
    $ConfirmPreference = "None"

    $Results = New-Object System.Collections.ArrayList

    $TotalCount = $Applications.Count
    $Index = 0

    if ($Mode -eq "Install") {
      Update-InstalledApplicationRegistryCache

      foreach ($Application in $Applications) {
        $Index++
        $ProgressQueue.Enqueue(("Installing {0} of {1}: {2}..." -f $Index, $TotalCount, $Application.Name))

        $AlreadyInstalled = Test-ApplicationInstalled -Application $Application

        if ($AlreadyInstalled) {
          Write-DeploymentLog -Message ("{0} is already installed. Skipped." -f $Application.Name) -Level "INFO"
          [void]$Results.Add([PSCustomObject]@{ ApplicationName = $Application.Name; Status = "Skipped"; Message = "$($Application.Name) is already installed. Skipped." })
          continue
        }

        $BlockingProcesses = @(Get-BlockingApplicationProcesses -Application $Application)

        if ($BlockingProcesses.Count -gt 0) {
          $ProcessNames = ($BlockingProcesses | Select-Object -ExpandProperty ProcessName -Unique | Sort-Object) -join ", "
          Write-DeploymentLog -Message ("{0} was skipped because these processes are running: {1}" -f $Application.Name, $ProcessNames) -Level "WARNING"
          [void]$Results.Add([PSCustomObject]@{ ApplicationName = $Application.Name; Status = "Blocked"; Message = "$($Application.Name) was skipped because these processes are running: $ProcessNames" })
          continue
        }

        $InstallerAvailable = Test-ApplicationInstallerAvailable -Application $Application

        if (-not $InstallerAvailable) {
          Write-DeploymentLog -Message ("Installer was not found or is unavailable for {0}." -f $Application.Name) -Level "ERROR"
          [void]$Results.Add([PSCustomObject]@{ ApplicationName = $Application.Name; Status = "NotFound"; Message = "Installer was not found or is unavailable for $($Application.Name)." })
          continue
        }

        $InstallationResult = Install-ApplicationByType -Application $Application

        [void]$Results.Add([PSCustomObject]@{ ApplicationName = $Application.Name; Status = $InstallationResult.Status; Message = $InstallationResult.Message })
      }
    }
    else {
      foreach ($Application in $Applications) {
        $Index++
        $ProgressQueue.Enqueue(("Uninstalling {0} of {1}: {2}..." -f $Index, $TotalCount, $Application.Name))

        $UninstallationResult = Uninstall-ApplicationByType -Application $Application

        [void]$Results.Add([PSCustomObject]@{ ApplicationName = $Application.Name; Status = $UninstallationResult.Status; Message = $UninstallationResult.Message })
      }
    }

    return @($Results)
  }

  $Runspace = [runspacefactory]::CreateRunspace()
  $Runspace.Open()

  $PowerShellInstance = [powershell]::Create()
  $PowerShellInstance.Runspace = $Runspace

  [void]$PowerShellInstance.AddScript($BackgroundScript)
  [void]$PowerShellInstance.AddArgument($RootPath)
  [void]$PowerShellInstance.AddArgument($LogPath)
  [void]$PowerShellInstance.AddArgument($Mode)
  [void]$PowerShellInstance.AddArgument($Applications)
  [void]$PowerShellInstance.AddArgument($ProgressQueue)

  $AsyncResult = $PowerShellInstance.BeginInvoke()

  $script:GuiQueueAsyncResult = $AsyncResult
  $script:GuiQueuePowerShell = $PowerShellInstance
  $script:GuiQueueRunspace = $Runspace
  $script:GuiQueueMode = $Mode
  $script:GuiQueueGridPanel = $GridPanel
  $script:GuiQueueCountText = $CountText
  $script:GuiQueueButtonsToDisable = $ButtonsToDisable
  $script:GuiQueuePreSkippedCount = $PreSkippedCount
  $script:GuiQueuePreFailureMessages = $PreFailureMessages
  $script:GuiQueueProgressQueue = $ProgressQueue

  $Timer = New-Object System.Windows.Threading.DispatcherTimer
  $Timer.Interval = [TimeSpan]::FromMilliseconds(300)
  $script:GuiQueueTimer = $Timer

  # Plain scriptblock -- deliberately NOT .GetNewClosure()'d. This function
  # returns before the timer ever ticks, so a closure would need to capture
  # every variable below by value; GetNewClosure() was already found earlier
  # in this file to break dot-sourced function resolution inside WPF event
  # handlers (that's why the toolbar buttons broke and had to be fixed by
  # removing it). Reading everything back from $script:GuiQueue* instead
  # mirrors the same proven-safe pattern New-GuiLogListRow's per-row click
  # handler already uses.
  $Timer.Add_Tick({
    $LatestProgressMessage = $null
    $DequeuedMessage = $null

    while ($script:GuiQueueProgressQueue.TryDequeue([ref]$DequeuedMessage)) {
      $LatestProgressMessage = $DequeuedMessage
    }

    if ($null -ne $LatestProgressMessage) {
      $script:GuiQueueCountText.Text = $LatestProgressMessage
    }

    if (-not $script:GuiQueueAsyncResult.IsCompleted) {
      return
    }

    $script:GuiQueueTimer.Stop()

    try {
      $QueueResults = @($script:GuiQueuePowerShell.EndInvoke($script:GuiQueueAsyncResult))

      if ($script:GuiQueuePowerShell.HadErrors) {
        foreach ($QueueError in $script:GuiQueuePowerShell.Streams.Error) {
          Write-DeploymentLog -Message ([string]$QueueError) -Level "ERROR"
        }
      }

      if ($script:GuiQueueMode -eq "Install") {
        $InstalledCount = @($QueueResults | Where-Object { $_.Status -eq "Installed" }).Count
        $SkippedCount = @($QueueResults | Where-Object { $_.Status -eq "Skipped" }).Count
        $BlockedCount = @($QueueResults | Where-Object { $_.Status -eq "Blocked" }).Count
        $NotFoundCount = @($QueueResults | Where-Object { $_.Status -eq "NotFound" }).Count
        $FailedResults = @($QueueResults | Where-Object { $_.Status -notin @("Installed", "Skipped", "Blocked", "NotFound") })
        $FailedCount = $FailedResults.Count

        $Summary = "Install summary`n`nInstalled: $InstalledCount`nSkipped: $SkippedCount`nBlocked: $BlockedCount`nFailed: $FailedCount`nNot Found: $NotFoundCount"

        $FailureMessages = @($FailedResults | ForEach-Object { $_.Message })
      }
      else {
        $UninstalledCount = @($QueueResults | Where-Object { $_.Status -eq "Uninstalled" }).Count
        $SkippedCount = @($QueueResults | Where-Object { $_.Status -eq "Skipped" }).Count + $script:GuiQueuePreSkippedCount
        $FailedResults = @($QueueResults | Where-Object { $_.Status -notin @("Uninstalled", "Skipped") })
        $FailedCount = $FailedResults.Count

        $Summary = "Uninstall summary`n`nUninstalled: $UninstalledCount`nSkipped: $SkippedCount`nFailed: $FailedCount"

        $FailureMessages = @($script:GuiQueuePreFailureMessages) + @($FailedResults | ForEach-Object { $_.Message })
      }

      if ($FailureMessages.Count -gt 0) {
        $Summary += "`n`nFailure details:`n" + ($FailureMessages -join "`n")
      }

      Update-ApplicationInstallationStatus
      Update-GuiApplicationGrid -GridPanel $script:GuiQueueGridPanel
      Update-GuiSelectedCount -CountText $script:GuiQueueCountText

      [System.Windows.MessageBox]::Show($Summary)
    }
    catch {
      [System.Windows.MessageBox]::Show("Queue error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
    finally {
      $script:GuiQueuePowerShell.Dispose()
      $script:GuiQueueRunspace.Close()
      $script:GuiQueueRunspace.Dispose()

      foreach ($Button in $script:GuiQueueButtonsToDisable) {
        $Button.IsEnabled = $true
      }

      $script:GuiQueueRunning = $false
    }
  })

  $Timer.Start()
}

function Invoke-GuiInstallQueue {
  param(
    [Parameter(Mandatory)]
    [System.Windows.Controls.ItemsControl]$GridPanel,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$CountText,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Button]$InstallButton,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Button]$UninstallButton
  )

  $SelectedApplications = @(Get-SelectedApplications)

  if ($SelectedApplications.Count -eq 0) {
    [System.Windows.MessageBox]::Show("No applications selected.")
    return
  }

  $ClonedApplications = @($SelectedApplications | ForEach-Object { $_.PSObject.Copy() })

  Start-GuiApplicationQueue -Mode "Install" -Applications $ClonedApplications -GridPanel $GridPanel -CountText $CountText -ButtonsToDisable @($InstallButton, $UninstallButton)
}

function Invoke-GuiUninstallQueue {
  param(
    [Parameter(Mandatory)]
    [System.Windows.Controls.ItemsControl]$GridPanel,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$CountText,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Button]$InstallButton,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Button]$UninstallButton
  )

  $SelectedApplications = @(Get-SelectedApplications)

  if ($SelectedApplications.Count -eq 0) {
    [System.Windows.MessageBox]::Show("No applications selected.")
    return
  }

  $ApplicationsToUninstall = @()
  $PreSkippedCount = 0

  foreach ($Application in $SelectedApplications) {
    $IsInstalled = Test-ApplicationInstalled -Application $Application

    if (-not $IsInstalled) {
      $PreSkippedCount++
      Write-DeploymentLog -Message ("{0} is not installed. Skipped." -f $Application.Name) -Level "INFO"
      continue
    }

    $Confirmation = [System.Windows.MessageBox]::Show(
      "Uninstall $($Application.Name)?",
      "Confirm Uninstall",
      [System.Windows.MessageBoxButton]::YesNo,
      [System.Windows.MessageBoxImage]::Warning
    )

    if ($Confirmation -ne [System.Windows.MessageBoxResult]::Yes) {
      $PreSkippedCount++
      Write-DeploymentLog -Message ("{0} uninstallation was declined." -f $Application.Name) -Level "INFO"
      continue
    }

    $ApplicationsToUninstall += $Application.PSObject.Copy()
  }

  Start-GuiApplicationQueue -Mode "Uninstall" -Applications $ApplicationsToUninstall -PreSkippedCount $PreSkippedCount -GridPanel $GridPanel -CountText $CountText -ButtonsToDisable @($InstallButton, $UninstallButton)
}

function Update-GuiWindowsConfigDeviceInfo {
  param(
    [Parameter(Mandatory)]
    [hashtable]$Fields
  )

  $Report = Get-WindowsConfigurationReport

  $Fields.ComputerName.Text = $Report.ComputerName
  $Fields.Manufacturer.Text = $Report.Manufacturer
  $Fields.Model.Text = $Report.Model
  $Fields.SerialNumber.Text = $Report.SerialNumber
  $Fields.NetworkType.Text = $Report.NetworkType
  $Fields.DomainWorkgroup.Text = $Report.DomainWorkgroup
  $Fields.OSEdition.Text = $Report.OSEdition
  $Fields.OSVersion.Text = $Report.OSVersion
  $Fields.OSBuildNumber.Text = $Report.OSBuildNumber
  $Fields.OSArchitecture.Text = $Report.OSArchitecture
  $Fields.LoggedUser.Text = $Report.LoggedUser
  $Fields.PowerPlan.Text = $Report.ActivePowerPlan
  $Fields.Sleep.Text = "Plugged: {0} | Battery: {1}" -f $Report.SleepAC, $Report.SleepDC

  $Fields.AdminStatus.Text = if ($Report.IsAdministrator) { "Yes" } else { "No" }
  $Fields.AdminStatus.Foreground = if ($Report.IsAdministrator) { "#34D399" } else { "#F2555A" }
}

function Update-GuiWindowsConfigCurrentName {
  param(
    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$CurrentNameText
  )

  $CurrentNameText.Text = Get-CurrentComputerName
}

function Update-GuiWindowsConfigLocalUsersList {
  param(
    [Parameter(Mandatory)]
    [System.Windows.Controls.StackPanel]$ListPanel
  )

  $ListPanel.Children.Clear()

  $DeploymentUsers = @(Get-DeploymentLocalStandardUsers)

  if ($DeploymentUsers.Count -eq 0) {
    $EmptyText = New-Object System.Windows.Controls.TextBlock
    $EmptyText.Text = "No standard users created yet."
    $EmptyText.FontSize = 11.5
    $EmptyText.Foreground = "#6B6F79"
    $ListPanel.Children.Add($EmptyText) | Out-Null
    return
  }

  foreach ($User in $DeploymentUsers) {
    $DetailText = if ([string]::IsNullOrWhiteSpace([string]$User.FullName)) { "Standard user" } else { [string]$User.FullName }
    $Row = New-GuiValidationStatusRow -StatusLabel "ACTIVE" -Passed $true -PrimaryText $User.Name -DetailText $DetailText
    $ListPanel.Children.Add($Row) | Out-Null
  }
}

function Update-GuiWindowsConfigPowerCurrentValues {
  param(
    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$CurrentPluggedInText,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$CurrentBatteryText
  )

  $Timeouts = Get-CurrentSleepTimeoutMinutes

  $CurrentPluggedInText.Text = Convert-SleepTimeoutMinutesToText -Minutes $Timeouts.PluggedInMinutes
  $CurrentBatteryText.Text = Convert-SleepTimeoutMinutesToText -Minutes $Timeouts.BatteryMinutes
}

function Invoke-GuiWindowsConfigurationRefresh {
  param(
    [Parameter(Mandatory)]
    [hashtable]$DeviceFields,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$CurrentNameText,

    [Parameter(Mandatory)]
    [System.Windows.Controls.StackPanel]$LocalUsersListPanel,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$CurrentPluggedInText,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$CurrentBatteryText
  )

  Update-GuiWindowsConfigDeviceInfo -Fields $DeviceFields
  Update-GuiWindowsConfigCurrentName -CurrentNameText $CurrentNameText
  Update-GuiWindowsConfigLocalUsersList -ListPanel $LocalUsersListPanel
  Update-GuiWindowsConfigPowerCurrentValues -CurrentPluggedInText $CurrentPluggedInText -CurrentBatteryText $CurrentBatteryText
}

function Invoke-GuiComputerRename {
  param(
    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBox]$NewNameTextBox,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$CurrentNameText
  )

  $Validation = Test-DeploymentComputerName -ComputerName $NewNameTextBox.Text

  if (-not $Validation.Valid) {
    [System.Windows.MessageBox]::Show($Validation.Message)
    return
  }

  $CurrentName = Get-CurrentComputerName

  $Confirmation = [System.Windows.MessageBox]::Show(
    "Rename this computer from $CurrentName to $($Validation.ComputerName)?",
    "Confirm Rename",
    [System.Windows.MessageBoxButton]::YesNo,
    [System.Windows.MessageBoxImage]::Warning
  )

  if ($Confirmation -ne [System.Windows.MessageBoxResult]::Yes) {
    return
  }

  $RenameResult = Set-DeploymentComputerName -NewName $Validation.ComputerName -Confirm:$false

  [System.Windows.MessageBox]::Show($RenameResult.Message)

  Update-GuiWindowsConfigCurrentName -CurrentNameText $CurrentNameText
}

function Invoke-GuiLocalUserCreation {
  param(
    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBox]$UserNameTextBox,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBox]$FullNameTextBox,

    [Parameter(Mandatory)]
    [System.Windows.Controls.PasswordBox]$PasswordBox,

    [Parameter(Mandatory)]
    [System.Windows.Controls.PasswordBox]$ConfirmPasswordBox,

    [Parameter(Mandatory)]
    [System.Windows.Controls.StackPanel]$ListPanel
  )

  try {
    $Validation = Test-DeploymentLocalUserName -UserName $UserNameTextBox.Text

    if (-not $Validation.Valid) {
      [System.Windows.MessageBox]::Show($Validation.Message)
      return
    }

    $UserName = $Validation.UserName

    if (Test-LocalUserExists -UserName $UserName) {
      [System.Windows.MessageBox]::Show("The local user already exists.")
      return
    }

    if ($PasswordBox.SecurePassword.Length -eq 0) {
      [System.Windows.MessageBox]::Show("The password cannot be empty.")
      return
    }

    if (-not (Test-SecurePasswordMatch -Password $PasswordBox.SecurePassword -Confirmation $ConfirmPasswordBox.SecurePassword)) {
      [System.Windows.MessageBox]::Show("The passwords do not match.")
      return
    }

    $FullName = $FullNameTextBox.Text

    $ConfirmationMessage = "Create local standard user '$UserName'?"

    if (-not [string]::IsNullOrWhiteSpace($FullName)) {
      $ConfirmationMessage = "Create local standard user '$UserName' ($FullName)?"
    }

    $Confirmation = [System.Windows.MessageBox]::Show(
      $ConfirmationMessage,
      "Confirm Create User",
      [System.Windows.MessageBoxButton]::YesNo,
      [System.Windows.MessageBoxImage]::Warning
    )

    if ($Confirmation -ne [System.Windows.MessageBoxResult]::Yes) {
      return
    }

    $CreationResult = New-DeploymentLocalStandardUser -UserName $UserName -Password $PasswordBox.SecurePassword -FullName $FullName -Confirm:$false

    [System.Windows.MessageBox]::Show($CreationResult.Message)

    Update-GuiWindowsConfigLocalUsersList -ListPanel $ListPanel
  }

  finally {
    $PasswordBox.Clear()
    $ConfirmPasswordBox.Clear()
  }
}

function Invoke-GuiPowerSettingsApply {
  param(
    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBox]$PluggedInMinutesTextBox,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBox]$BatteryMinutesTextBox,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$CurrentPluggedInText,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$CurrentBatteryText
  )

  $PluggedInTest = Test-SleepTimeoutMinutes -Value $PluggedInMinutesTextBox.Text -SettingName "Plugged-in sleep timeout"

  if (-not $PluggedInTest.Valid) {
    [System.Windows.MessageBox]::Show($PluggedInTest.Message)
    return
  }

  $BatteryTest = Test-SleepTimeoutMinutes -Value $BatteryMinutesTextBox.Text -SettingName "Battery sleep timeout"

  if (-not $BatteryTest.Valid) {
    [System.Windows.MessageBox]::Show($BatteryTest.Message)
    return
  }

  $Confirmation = [System.Windows.MessageBox]::Show(
    "Set plugged-in sleep to $($PluggedInTest.Minutes) minutes and battery sleep to $($BatteryTest.Minutes) minutes?",
    "Confirm Power Settings",
    [System.Windows.MessageBoxButton]::YesNo,
    [System.Windows.MessageBoxImage]::Warning
  )

  if ($Confirmation -ne [System.Windows.MessageBoxResult]::Yes) {
    return
  }

  $Result = Set-DeploymentSleepTimeouts -PluggedInMinutes $PluggedInTest.Minutes -BatteryMinutes $BatteryTest.Minutes -Confirm:$false

  [System.Windows.MessageBox]::Show($Result.Message)

  Update-GuiWindowsConfigPowerCurrentValues -CurrentPluggedInText $CurrentPluggedInText -CurrentBatteryText $CurrentBatteryText
}

function Show-MainWindow {
  Add-Type -AssemblyName PresentationFramework

  Initialize-DeploymentLog -Version $AppVersion

  Initialize-Applications | Out-Null
  Update-ApplicationInstallationStatus

  $XamlPath = Join-Path $script:ITDeploymentToolRoot "Modules\Gui\MainWindow.xaml"

  [xml]$WindowXaml = Get-Content -LiteralPath $XamlPath -Raw

  $Reader = New-Object System.Xml.XmlNodeReader $WindowXaml
  $Window = [Windows.Markup.XamlReader]::Load($Reader)

  # Nunito is bundled as a variable font rather than installed system-wide,
  # since this tool is copied directly to technician machines rather than
  # installed. Loaded via an absolute folder URI (not a relative XAML path)
  # because XamlReader.Load has no base URI to resolve a relative FontFamily
  # reference against here -- every other path in this app already uses
  # $script:ITDeploymentToolRoot for the same reason. Falls back to the
  # XAML's own Segoe UI default if the font file is ever missing (e.g. not
  # yet copied to this machine), rather than failing to start.
  try {
    $FontsDirectory = Join-Path $script:ITDeploymentToolRoot "Modules\Gui\Fonts"
    $FontsUri = New-Object System.Uri(($FontsDirectory.TrimEnd('\') + '\'), [System.UriKind]::Absolute)
    $Window.FontFamily = New-Object System.Windows.Media.FontFamily($FontsUri, "./#Nunito")
  }
  catch {
    Write-DeploymentLog -Message "Nunito font could not be loaded; falling back to the default font. $($_.Exception.Message)" -Level "WARNING"
  }

  $AppGridPanel = $Window.FindName("AppGridPanel")
  $SelectedCountText = $Window.FindName("SelectedCountText")
  $SelectAllButton = $Window.FindName("SelectAllButton")
  $SelectRecommendedButton = $Window.FindName("SelectRecommendedButton")
  $ClearAllButton = $Window.FindName("ClearAllButton")
  $InstallSelectedButton = $Window.FindName("InstallSelectedButton")
  $UninstallSelectedButton = $Window.FindName("UninstallSelectedButton")
  $DeploymentValidationPanel = $Window.FindName("DeploymentValidationPanel")
  $ValidationSummaryText = $Window.FindName("ValidationSummaryText")
  $RerunValidationButton = $Window.FindName("RerunValidationButton")
  $DeploymentLogsPanel = $Window.FindName("DeploymentLogsPanel")
  $LogContentTextBox = $Window.FindName("LogContentTextBox")
  $RefreshLogsButton = $Window.FindName("RefreshLogsButton")
  $OpenLogsFolderButton = $Window.FindName("OpenLogsFolderButton")
  $RefreshWindowsConfigButton = $Window.FindName("RefreshWindowsConfigButton")
  $CurrentComputerNameText = $Window.FindName("CurrentComputerNameText")
  $NewComputerNameTextBox = $Window.FindName("NewComputerNameTextBox")
  $RenameComputerButton = $Window.FindName("RenameComputerButton")
  $LocalUsersListPanel = $Window.FindName("LocalUsersListPanel")
  $NewUserNameTextBox = $Window.FindName("NewUserNameTextBox")
  $NewUserFullNameTextBox = $Window.FindName("NewUserFullNameTextBox")
  $NewUserPasswordBox = $Window.FindName("NewUserPasswordBox")
  $NewUserConfirmPasswordBox = $Window.FindName("NewUserConfirmPasswordBox")
  $CreateUserButton = $Window.FindName("CreateUserButton")
  $CurrentPluggedInText = $Window.FindName("CurrentPluggedInText")
  $CurrentBatteryText = $Window.FindName("CurrentBatteryText")
  $PluggedInMinutesTextBox = $Window.FindName("PluggedInMinutesTextBox")
  $BatteryMinutesTextBox = $Window.FindName("BatteryMinutesTextBox")
  $ApplyPowerSettingsButton = $Window.FindName("ApplyPowerSettingsButton")

  $WindowsConfigDeviceFields = @{
    ComputerName    = $Window.FindName("DeviceComputerNameText")
    Manufacturer    = $Window.FindName("DeviceManufacturerText")
    Model           = $Window.FindName("DeviceModelText")
    SerialNumber    = $Window.FindName("DeviceSerialNumberText")
    NetworkType     = $Window.FindName("DeviceNetworkTypeText")
    DomainWorkgroup = $Window.FindName("DeviceDomainWorkgroupText")
    OSEdition       = $Window.FindName("DeviceOSEditionText")
    OSVersion       = $Window.FindName("DeviceOSVersionText")
    OSBuildNumber   = $Window.FindName("DeviceOSBuildNumberText")
    OSArchitecture  = $Window.FindName("DeviceOSArchitectureText")
    LoggedUser      = $Window.FindName("DeviceLoggedUserText")
    AdminStatus     = $Window.FindName("DeviceAdminStatusText")
    PowerPlan       = $Window.FindName("DevicePowerPlanText")
    Sleep           = $Window.FindName("DeviceSleepText")
  }

  $InitialTimeouts = Get-CurrentSleepTimeoutMinutes
  $PluggedInMinutesTextBox.Text = [string]$InitialTimeouts.PluggedInMinutes
  $BatteryMinutesTextBox.Text = [string]$InitialTimeouts.BatteryMinutes

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

  $InstallSelectedButton.Add_Click({
    try {
      Invoke-GuiInstallQueue -GridPanel $AppGridPanel -CountText $SelectedCountText -InstallButton $InstallSelectedButton -UninstallButton $UninstallSelectedButton
    }
    catch {
      [System.Windows.MessageBox]::Show("Install error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
  })

  $UninstallSelectedButton.Add_Click({
    try {
      Invoke-GuiUninstallQueue -GridPanel $AppGridPanel -CountText $SelectedCountText -InstallButton $InstallSelectedButton -UninstallButton $UninstallSelectedButton
    }
    catch {
      [System.Windows.MessageBox]::Show("Uninstall error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
  })

  $RerunValidationButton.Add_Click({
    try {
      Invoke-GuiDeploymentValidation -ValidationPanel $DeploymentValidationPanel -SummaryText $ValidationSummaryText
    }
    catch {
      [System.Windows.MessageBox]::Show("Deployment validation error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
  })

  $RefreshLogsButton.Add_Click({
    try {
      Update-GuiLogsList -ListPanel $DeploymentLogsPanel -ContentTextBox $LogContentTextBox
    }
    catch {
      [System.Windows.MessageBox]::Show("Refresh error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
  })

  $OpenLogsFolderButton.Add_Click({
    try {
      Open-DeploymentLogsFolder
    }
    catch {
      [System.Windows.MessageBox]::Show("Unable to open the Logs folder: $($_.Exception.Message)")
    }
  })

  $RefreshWindowsConfigButton.Add_Click({
    try {
      Invoke-GuiWindowsConfigurationRefresh -DeviceFields $WindowsConfigDeviceFields -CurrentNameText $CurrentComputerNameText -LocalUsersListPanel $LocalUsersListPanel -CurrentPluggedInText $CurrentPluggedInText -CurrentBatteryText $CurrentBatteryText
    }
    catch {
      [System.Windows.MessageBox]::Show("Refresh error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
  })

  $RenameComputerButton.Add_Click({
    try {
      Invoke-GuiComputerRename -NewNameTextBox $NewComputerNameTextBox -CurrentNameText $CurrentComputerNameText
    }
    catch {
      [System.Windows.MessageBox]::Show("Rename error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
  })

  $CreateUserButton.Add_Click({
    try {
      Invoke-GuiLocalUserCreation -UserNameTextBox $NewUserNameTextBox -FullNameTextBox $NewUserFullNameTextBox -PasswordBox $NewUserPasswordBox -ConfirmPasswordBox $NewUserConfirmPasswordBox -ListPanel $LocalUsersListPanel
    }
    catch {
      [System.Windows.MessageBox]::Show("Create user error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
  })

  $ApplyPowerSettingsButton.Add_Click({
    try {
      Invoke-GuiPowerSettingsApply -PluggedInMinutesTextBox $PluggedInMinutesTextBox -BatteryMinutesTextBox $BatteryMinutesTextBox -CurrentPluggedInText $CurrentPluggedInText -CurrentBatteryText $CurrentBatteryText
    }
    catch {
      [System.Windows.MessageBox]::Show("Apply power settings error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
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

  $script:GuiQueueRunning = $false
  $script:GuiNavBorders = @($NavApplications, $NavWindowsConfig, $NavDeploymentLogs, $NavDeploymentValidation)
  $script:GuiNavTexts = @($NavApplicationsText, $NavWindowsConfigText, $NavDeploymentLogsText, $NavDeploymentValidationText)
  $script:GuiApplicationsToolbar = $Window.FindName("ApplicationsToolbar")
  $script:GuiApplicationsScrollViewer = $Window.FindName("ApplicationsScrollViewer")
  $script:GuiPlaceholderText = $Window.FindName("PlaceholderText")
  $script:GuiDeploymentValidationToolbar = $Window.FindName("DeploymentValidationToolbar")
  $script:GuiDeploymentValidationScrollViewer = $Window.FindName("DeploymentValidationScrollViewer")
  $script:GuiDeploymentValidationPanel = $DeploymentValidationPanel
  $script:GuiValidationSummaryText = $ValidationSummaryText
  $script:GuiDeploymentLogsToolbar = $Window.FindName("DeploymentLogsToolbar")
  $script:GuiDeploymentLogsContent = $Window.FindName("DeploymentLogsContent")
  $script:GuiDeploymentLogsPanel = $DeploymentLogsPanel
  $script:GuiLogContentTextBox = $LogContentTextBox
  $script:GuiWindowsConfigToolbar = $Window.FindName("WindowsConfigToolbar")
  $script:GuiWindowsConfigScrollViewer = $Window.FindName("WindowsConfigScrollViewer")
  $script:GuiWindowsConfigDeviceFields = $WindowsConfigDeviceFields
  $script:GuiCurrentComputerNameText = $CurrentComputerNameText
  $script:GuiLocalUsersListPanel = $LocalUsersListPanel
  $script:GuiCurrentPluggedInText = $CurrentPluggedInText
  $script:GuiCurrentBatteryText = $CurrentBatteryText

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

  $Window.Add_Closing({
    if ($script:GuiQueueRunning) {
      $_.Cancel = $true
      [System.Windows.MessageBox]::Show("An install or uninstall is still running. Please wait for it to finish before closing.")
    }
  })

  [void]$Window.ShowDialog()

  Complete-DeploymentLog
}
