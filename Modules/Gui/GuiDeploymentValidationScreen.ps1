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
  $StatusColumn.Width = "78"
  $RowGrid.ColumnDefinitions.Add($StatusColumn)

  $NameColumn = New-Object System.Windows.Controls.ColumnDefinition
  $NameColumn.Width = "220"
  $RowGrid.ColumnDefinitions.Add($NameColumn)

  $DetailColumn = New-Object System.Windows.Controls.ColumnDefinition
  $DetailColumn.Width = "*"
  $RowGrid.ColumnDefinitions.Add($DetailColumn)

  $StatusPanel = New-Object System.Windows.Controls.StackPanel
  $StatusPanel.Orientation = "Horizontal"

  $StatusIcon = New-GuiStatusIcon -Passed $Passed
  $StatusIcon.VerticalAlignment = "Center"
  $StatusIcon.Margin = "0,0,5,0"
  $StatusPanel.Children.Add($StatusIcon) | Out-Null

  $StatusText = New-Object System.Windows.Controls.TextBlock
  $StatusText.Text = $StatusLabel
  $StatusText.FontSize = 10.5
  $StatusText.FontWeight = "Bold"
  $StatusText.VerticalAlignment = "Center"
  $StatusText.Foreground = if ($Passed) { "#34D399" } else { "#F2555A" }
  $StatusPanel.Children.Add($StatusText) | Out-Null

  [System.Windows.Controls.Grid]::SetColumn($StatusPanel, 0)
  $RowGrid.Children.Add($StatusPanel) | Out-Null

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
    [ValidateSet("DeviceReadiness", "InstallerPackages")]
    [string]$IconName,

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
  $HeaderGrid.Margin = "0,0,0,12"

  $TitleColumn = New-Object System.Windows.Controls.ColumnDefinition
  $TitleColumn.Width = "*"
  $HeaderGrid.ColumnDefinitions.Add($TitleColumn)

  $CountColumn = New-Object System.Windows.Controls.ColumnDefinition
  $CountColumn.Width = "Auto"
  $HeaderGrid.ColumnDefinitions.Add($CountColumn)

  $TitlePanel = New-Object System.Windows.Controls.StackPanel
  $TitlePanel.Orientation = "Horizontal"
  [System.Windows.Controls.Grid]::SetColumn($TitlePanel, 0)
  $HeaderGrid.Children.Add($TitlePanel) | Out-Null

  $HeaderIcon = New-GuiSectionHeaderIcon -IconName $IconName
  $HeaderIcon.Margin = "0,0,8,0"
  $TitlePanel.Children.Add($HeaderIcon) | Out-Null

  $Header = New-Object System.Windows.Controls.TextBlock
  $Header.Text = $SectionTitle.ToUpper()
  $Header.FontSize = 12
  $Header.FontWeight = "Bold"
  $Header.Foreground = "#9A9EA8"
  $Header.VerticalAlignment = "Center"
  $TitlePanel.Children.Add($Header) | Out-Null

  $AllPassed = ($PassedCount -eq $TotalCount)

  $CountBadge = New-Object System.Windows.Controls.Border
  $CountBadge.CornerRadius = "10"
  $CountBadge.Padding = "10,3"
  $CountBadge.Background = if ($AllPassed) { "#1934D399" } else { "#1AF2555A" }
  [System.Windows.Controls.Grid]::SetColumn($CountBadge, 1)
  $HeaderGrid.Children.Add($CountBadge) | Out-Null

  $CountText = New-Object System.Windows.Controls.TextBlock
  $CountText.Text = "$PassedCount / $TotalCount passed"
  $CountText.FontSize = 11
  $CountText.FontWeight = "SemiBold"
  $CountText.Foreground = if ($AllPassed) { "#34D399" } else { "#F2555A" }
  $CountBadge.Child = $CountText

  $Stack.Children.Add($HeaderGrid) | Out-Null

  foreach ($Row in $Rows) {
    $Stack.Children.Add($Row) | Out-Null
  }

  return $Card
}

function Start-GuiDeploymentValidationLoad {
  param(
    [Parameter(Mandatory)]
    [System.Windows.Controls.StackPanel]$ValidationPanel,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$SummaryText,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Button]$RerunButton
  )

  $RerunButton.IsEnabled = $false
  Show-GuiScreenLoadingState -Panel $ValidationPanel -Message "Checking deployment readiness..."

  $RootPath = $script:ITDeploymentToolRoot
  $LogPath = $script:LogFilePath
  $ClonedApplications = @($script:Applications | ForEach-Object { $_.PSObject.Copy() })

  # The device readiness checks (admin, internet, restart, CrowdStrike, Office,
  # etc.) and installer package checks are all read-only, so they are safe to
  # run off the UI thread. Re-dot-sourcing the modules they depend on inside a
  # fresh runspace mirrors the same background-execution pattern already
  # proven for install/uninstall queues in GuiApplicationsScreen.ps1.
  $BackgroundScript = {
    param(
      [string]$RootPath,
      [string]$LogPath,
      [object[]]$ApplicationsParam
    )

    $ModulePaths = @(
      "Core\Logging.ps1"
      "Validation\SystemChecks.ps1"
      "Applications\ApplicationCatalog.ps1"
      "Applications\InstalledApplications.ps1"
      "Applications\ApplicationProcessCheck.ps1"
      "Applications\MicrosoftTeams.ps1"
      "Windows\ComputerNameConfiguration.ps1"
      "Windows\LocalUserConfiguration.ps1"
      "Windows\PowerConfiguration.ps1"
      "Installation\CrowdStrikeInstaller.ps1"
      "Installation\OfficeIsoInstaller.ps1"
      "Installation\Office2021ImgInstaller.ps1"
      "Validation\DeploymentValidation.ps1"
      "Validation\InstallerPackageReadiness.ps1"
    )

    # ApplicationCatalog.ps1's own top-level code resets $script:Applications
    # to an empty array when dot-sourced. Dot-sourcing does not create a new
    # scope, so a parameter literally named $Applications here would be the
    # same variable as $script:Applications and would get silently clobbered
    # mid-loop -- that's why this parameter is named $ApplicationsParam
    # instead, and $script:Applications is only (re)assigned after every
    # module has finished loading.
    foreach ($ModulePath in $ModulePaths) {
      . (Join-Path $RootPath "Modules\$ModulePath")
    }

    $script:ITDeploymentToolRoot = $RootPath
    $script:LogFilePath = $LogPath
    $script:Applications = $ApplicationsParam

    $SystemInfo = [PSCustomObject]@{
      ComputerName = $null; LoggedUser = $null; Manufacturer = $null; Model = $null; SerialNumber = $null
      WindowsEdition = $null; IsAdministrator = $false; InternetStatus = $false; WingetAvailable = $false
    }

    $DeviceResults = @(Get-DeploymentValidationResults)
    Write-DeploymentValidationResultsToLog -Results $DeviceResults
    $ReadinessResults = @(Get-InstallerPackageReadiness -Applications $ApplicationsParam)

    return [PSCustomObject]@{
      DeviceResults    = $DeviceResults
      ReadinessResults = $ReadinessResults
    }
  }

  $Runspace = [runspacefactory]::CreateRunspace()
  $Runspace.Open()

  $PowerShellInstance = [powershell]::Create()
  $PowerShellInstance.Runspace = $Runspace

  [void]$PowerShellInstance.AddScript($BackgroundScript)
  [void]$PowerShellInstance.AddArgument($RootPath)
  [void]$PowerShellInstance.AddArgument($LogPath)
  [void]$PowerShellInstance.AddArgument($ClonedApplications)

  $AsyncResult = $PowerShellInstance.BeginInvoke()

  $script:GuiValidationAsyncResult = $AsyncResult
  $script:GuiValidationPowerShell = $PowerShellInstance
  $script:GuiValidationRunspace = $Runspace
  $script:GuiValidationPanel = $ValidationPanel
  $script:GuiValidationSummaryTextControl = $SummaryText
  $script:GuiValidationRerunButton = $RerunButton

  $Timer = New-Object System.Windows.Threading.DispatcherTimer
  $Timer.Interval = [TimeSpan]::FromMilliseconds(200)
  $script:GuiValidationTimer = $Timer

  # Plain scriptblock -- deliberately NOT .GetNewClosure()'d, matching
  # Start-GuiApplicationQueue's own timer handler (see the comment there for
  # why GetNewClosure breaks dot-sourced function resolution in this app).
  $Timer.Add_Tick({
    if (-not $script:GuiValidationAsyncResult.IsCompleted) {
      return
    }

    $script:GuiValidationTimer.Stop()

    try {
      $Result = $script:GuiValidationPowerShell.EndInvoke($script:GuiValidationAsyncResult) | Select-Object -First 1

      if ($script:GuiValidationPowerShell.HadErrors) {
        foreach ($ValidationError in $script:GuiValidationPowerShell.Streams.Error) {
          Write-DeploymentLog -Message ([string]$ValidationError) -Level "ERROR"
        }
      }

      $Panel = $script:GuiValidationPanel
      $Panel.Children.Clear()

      $DeviceResults = @($Result.DeviceResults)
      $DevicePassedCount = @($DeviceResults | Where-Object { $_.Passed }).Count
      $DeviceRows = @($DeviceResults | ForEach-Object { New-GuiDeviceReadinessRow -Result $_ })
      $DeviceCard = New-GuiValidationSectionCard -SectionTitle "Device Readiness Checks" -IconName "DeviceReadiness" -Rows $DeviceRows -PassedCount $DevicePassedCount -TotalCount $DeviceResults.Count
      $Panel.Children.Add($DeviceCard) | Out-Null

      $ReadinessResults = @($Result.ReadinessResults)
      $ReadinessPassedCount = @($ReadinessResults | Where-Object { $_.Status -eq "READY" }).Count
      $ReadinessRows = @($ReadinessResults | ForEach-Object { New-GuiInstallerReadinessRow -Result $_ })
      $ReadinessCard = New-GuiValidationSectionCard -SectionTitle "Installer Package Status" -IconName "InstallerPackages" -Rows $ReadinessRows -PassedCount $ReadinessPassedCount -TotalCount $ReadinessResults.Count
      $Panel.Children.Add($ReadinessCard) | Out-Null

      $TotalPassed = $DevicePassedCount + $ReadinessPassedCount
      $TotalChecks = $DeviceResults.Count + $ReadinessResults.Count
      $TotalFailed = $TotalChecks - $TotalPassed

      $script:GuiValidationSummaryTextControl.Text = "$TotalPassed passed, $TotalFailed failed"
      $script:GuiValidationSummaryTextControl.Foreground = if ($TotalFailed -eq 0) { "#34D399" } else { "#F2555A" }

      Start-GuiFadeIn -Element $Panel
    }
    catch {
      [System.Windows.MessageBox]::Show("Deployment validation error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
    finally {
      $script:GuiValidationPowerShell.Dispose()
      $script:GuiValidationRunspace.Close()
      $script:GuiValidationRunspace.Dispose()
      $script:GuiValidationRerunButton.IsEnabled = $true
    }
  })

  $Timer.Start()
}
