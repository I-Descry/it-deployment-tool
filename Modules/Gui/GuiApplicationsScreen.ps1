# ============================================================
# GUI APPLICATIONS SCREEN
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
    $RecommendedIcon = New-GuiRecommendedIcon
    $RecommendedIcon.Margin = "8,0,0,0"
    $RecommendedIcon.VerticalAlignment = "Center"
    [System.Windows.Controls.Grid]::SetColumn($RecommendedIcon, 1)
    $RowGrid.Children.Add($RecommendedIcon) | Out-Null
  }

  $StatusPanel = New-Object System.Windows.Controls.StackPanel
  $StatusPanel.Orientation = "Horizontal"
  $StatusPanel.VerticalAlignment = "Center"
  $StatusPanel.Margin = "8,0,0,0"

  $StatusColor = if ($Application.Installed) { "#34D399" } else { "#6B6F79" }

  $StatusDot = New-Object System.Windows.Shapes.Ellipse
  $StatusDot.Width = 5
  $StatusDot.Height = 5
  $StatusDot.Fill = $StatusColor
  $StatusDot.VerticalAlignment = "Center"
  $StatusDot.Margin = "0,0,5,0"
  $StatusPanel.Children.Add($StatusDot) | Out-Null

  $StatusText = New-Object System.Windows.Controls.TextBlock
  $StatusText.Text = if ($Application.Installed) { "Installed" } else { "Not Installed" }
  $StatusText.FontSize = 10.5
  $StatusText.FontWeight = "SemiBold"
  $StatusText.Foreground = $StatusColor
  $StatusPanel.Children.Add($StatusText) | Out-Null

  [System.Windows.Controls.Grid]::SetColumn($StatusPanel, 2)
  $RowGrid.Children.Add($StatusPanel) | Out-Null

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

  $HeaderPanel = New-Object System.Windows.Controls.StackPanel
  $HeaderPanel.Orientation = "Horizontal"
  $HeaderPanel.Margin = "0,0,0,8"

  $HeaderIcon = New-GuiCategoryIcon -CategoryName $CategoryName -Color "#9A9EA8"
  $HeaderIcon.Margin = "0,0,8,0"
  $HeaderPanel.Children.Add($HeaderIcon) | Out-Null

  $Header = New-Object System.Windows.Controls.TextBlock
  $Header.Text = $CategoryName.ToUpper()
  $Header.FontSize = 11
  $Header.FontWeight = "Bold"
  $Header.Foreground = "#9A9EA8"
  $Header.VerticalAlignment = "Center"
  $HeaderPanel.Children.Add($Header) | Out-Null

  $Stack.Children.Add($HeaderPanel) | Out-Null

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
