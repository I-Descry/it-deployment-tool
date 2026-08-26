# ============================================================
# GUI WINDOWS CONFIGURATION SCREEN
# ============================================================
# Update-GuiWindowsConfigLocalUsersList reuses New-GuiValidationStatusRow
# from GuiDeploymentValidationScreen.ps1, so this file must load after it.

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
  $Fields.Processor.Text = $Report.Processor
  $Fields.Memory.Text = $Report.MemoryGB
  $Fields.Storage.Text = $Report.Storage

  $Fields.AdminStatus.Text = if ($Report.IsAdministrator) { "Yes" } else { "No" }
  $Fields.AdminStatus.Foreground = if ($Report.IsAdministrator) { "#34D399" } else { "#F2555A" }
  $Fields.AdminStatusPill.Background = if ($Report.IsAdministrator) { "#1934D399" } else { "#1AF2555A" }

  $Fields.TpmStatus.Text = $Report.TpmStatus
  $Fields.TpmStatus.Foreground = if ($Report.TpmReady) { "#34D399" } else { "#6B6F79" }
  $Fields.TpmStatusPill.Background = if ($Report.TpmReady) { "#1934D399" } else { "#23262E" }
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

function Start-GuiWindowsConfigLoad {
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
    [System.Windows.Controls.TextBlock]$CurrentBatteryText,

    # Windows Setup and Device Details each have their own Refresh button over
    # this one shared load, so both are disabled for its duration.
    [Parameter(Mandatory)]
    [System.Windows.Controls.Button[]]$RefreshButtons,

    [Parameter(Mandatory)]
    [System.Windows.Controls.ScrollViewer]$ScrollViewer
  )

  foreach ($RefreshButton in $RefreshButtons) {
    $RefreshButton.IsEnabled = $false
  }

  $RootPath = $script:ITDeploymentToolRoot

  # Used only for the screen's first load (see Switch-GuiScreen), where the
  # CIM/BIOS/powercfg queries are guaranteed to be a real, un-cached cost.
  # The Refresh button keeps using the synchronous Invoke-GuiWindowsConfigurationRefresh
  # below, since by then the identity cache in Get-WindowsConfigurationIdentity
  # (WindowsConfiguration.ps1) is already warm in the main runspace and that
  # path is already fast (~60ms) -- backgrounding it would add complexity for
  # no perceptible benefit. A fresh background runspace has its own empty
  # cache, so this path always pays the full first-query cost.
  $BackgroundScript = {
    param([string]$RootPath)

    $ModulePaths = @(
      "Windows\ComputerNameConfiguration.ps1"
      "Windows\LocalUserConfiguration.ps1"
      "Windows\PowerConfiguration.ps1"
      "Windows\WindowsConfiguration.ps1"
    )

    foreach ($ModulePath in $ModulePaths) {
      . (Join-Path $RootPath "Modules\$ModulePath")
    }

    $script:ITDeploymentToolRoot = $RootPath

    $Report = Get-WindowsConfigurationReport
    $CurrentName = Get-CurrentComputerName
    $LocalUsers = @(Get-DeploymentLocalStandardUsers)
    $Timeouts = Get-CurrentSleepTimeoutMinutes

    return [PSCustomObject]@{
      Report      = $Report
      CurrentName = $CurrentName
      LocalUsers  = $LocalUsers
      Timeouts    = $Timeouts
    }
  }

  $Runspace = [runspacefactory]::CreateRunspace()
  $Runspace.Open()

  $PowerShellInstance = [powershell]::Create()
  $PowerShellInstance.Runspace = $Runspace

  [void]$PowerShellInstance.AddScript($BackgroundScript)
  [void]$PowerShellInstance.AddArgument($RootPath)

  $AsyncResult = $PowerShellInstance.BeginInvoke()

  $script:GuiWindowsConfigLoadAsyncResult = $AsyncResult
  $script:GuiWindowsConfigLoadPowerShell = $PowerShellInstance
  $script:GuiWindowsConfigLoadRunspace = $Runspace
  $script:GuiWindowsConfigLoadDeviceFields = $DeviceFields
  $script:GuiWindowsConfigLoadCurrentNameText = $CurrentNameText
  $script:GuiWindowsConfigLoadLocalUsersListPanel = $LocalUsersListPanel
  $script:GuiWindowsConfigLoadCurrentPluggedInText = $CurrentPluggedInText
  $script:GuiWindowsConfigLoadCurrentBatteryText = $CurrentBatteryText
  $script:GuiWindowsConfigLoadRefreshButtons = $RefreshButtons
  $script:GuiWindowsConfigLoadScrollViewer = $ScrollViewer

  $Timer = New-Object System.Windows.Threading.DispatcherTimer
  $Timer.Interval = [TimeSpan]::FromMilliseconds(200)
  $script:GuiWindowsConfigLoadTimer = $Timer

  # Plain scriptblock -- deliberately NOT .GetNewClosure()'d, matching every
  # other background-runspace timer handler in this app.
  $Timer.Add_Tick({
    if (-not $script:GuiWindowsConfigLoadAsyncResult.IsCompleted) {
      return
    }

    $script:GuiWindowsConfigLoadTimer.Stop()

    try {
      $Result = $script:GuiWindowsConfigLoadPowerShell.EndInvoke($script:GuiWindowsConfigLoadAsyncResult) | Select-Object -First 1

      if ($script:GuiWindowsConfigLoadPowerShell.HadErrors) {
        foreach ($LoadError in $script:GuiWindowsConfigLoadPowerShell.Streams.Error) {
          Write-DeploymentLog -Message ([string]$LoadError) -Level "ERROR"
        }
      }

      $Report = $Result.Report
      $Fields = $script:GuiWindowsConfigLoadDeviceFields

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
      $Fields.Processor.Text = $Report.Processor
      $Fields.Memory.Text = $Report.MemoryGB
      $Fields.Storage.Text = $Report.Storage
      $Fields.AdminStatus.Text = if ($Report.IsAdministrator) { "Yes" } else { "No" }
      $Fields.AdminStatus.Foreground = if ($Report.IsAdministrator) { "#34D399" } else { "#F2555A" }
      $Fields.AdminStatusPill.Background = if ($Report.IsAdministrator) { "#1934D399" } else { "#1AF2555A" }
      $Fields.TpmStatus.Text = $Report.TpmStatus
      $Fields.TpmStatus.Foreground = if ($Report.TpmReady) { "#34D399" } else { "#6B6F79" }
      $Fields.TpmStatusPill.Background = if ($Report.TpmReady) { "#1934D399" } else { "#23262E" }

      $script:GuiWindowsConfigLoadCurrentNameText.Text = $Result.CurrentName

      $ListPanel = $script:GuiWindowsConfigLoadLocalUsersListPanel
      $ListPanel.Children.Clear()
      $LocalUsers = @($Result.LocalUsers)

      if ($LocalUsers.Count -eq 0) {
        $EmptyText = New-Object System.Windows.Controls.TextBlock
        $EmptyText.Text = "No standard users created yet."
        $EmptyText.FontSize = 11.5
        $EmptyText.Foreground = "#6B6F79"
        $ListPanel.Children.Add($EmptyText) | Out-Null
      }
      else {
        foreach ($User in $LocalUsers) {
          $DetailText = if ([string]::IsNullOrWhiteSpace([string]$User.FullName)) { "Standard user" } else { [string]$User.FullName }
          $Row = New-GuiValidationStatusRow -StatusLabel "ACTIVE" -Passed $true -PrimaryText $User.Name -DetailText $DetailText
          $ListPanel.Children.Add($Row) | Out-Null
        }
      }

      $script:GuiWindowsConfigLoadCurrentPluggedInText.Text = Convert-SleepTimeoutMinutesToText -Minutes $Result.Timeouts.PluggedInMinutes
      $script:GuiWindowsConfigLoadCurrentBatteryText.Text = Convert-SleepTimeoutMinutesToText -Minutes $Result.Timeouts.BatteryMinutes

      Start-GuiFadeIn -Element $script:GuiWindowsConfigLoadScrollViewer
    }
    catch {
      [System.Windows.MessageBox]::Show("Device information load error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)")
    }
    finally {
      $script:GuiWindowsConfigLoadPowerShell.Dispose()
      $script:GuiWindowsConfigLoadRunspace.Close()
      $script:GuiWindowsConfigLoadRunspace.Dispose()
      foreach ($LoadRefreshButton in $script:GuiWindowsConfigLoadRefreshButtons) {
        $LoadRefreshButton.IsEnabled = $true
      }
    }
  })

  $Timer.Start()
}

function Get-GuiDeviceDetailsSummary {
  param(
    [Parameter(Mandatory)]
    [hashtable]$DeviceFields
  )

  $Lines = @(
    "Computer Name     : {0}" -f $DeviceFields.ComputerName.Text
    "Manufacturer      : {0}" -f $DeviceFields.Manufacturer.Text
    "Model             : {0}" -f $DeviceFields.Model.Text
    "Serial Number     : {0}" -f $DeviceFields.SerialNumber.Text
    "Network Type      : {0}" -f $DeviceFields.NetworkType.Text
    "Domain/Workgroup  : {0}" -f $DeviceFields.DomainWorkgroup.Text
    "OS Edition        : {0}" -f $DeviceFields.OSEdition.Text
    "OS Version        : {0}" -f $DeviceFields.OSVersion.Text
    "Build Number      : {0}" -f $DeviceFields.OSBuildNumber.Text
    "Architecture      : {0}" -f $DeviceFields.OSArchitecture.Text
    "Logged User       : {0}" -f $DeviceFields.LoggedUser.Text
    "Administrator     : {0}" -f $DeviceFields.AdminStatus.Text
    "Active Power Plan : {0}" -f $DeviceFields.PowerPlan.Text
    "Sleep Settings    : {0}" -f $DeviceFields.Sleep.Text
    "Processor         : {0}" -f $DeviceFields.Processor.Text
    "Memory            : {0}" -f $DeviceFields.Memory.Text
    "Storage           : {0}" -f $DeviceFields.Storage.Text
    "TPM               : {0}" -f $DeviceFields.TpmStatus.Text
  )

  return ($Lines -join [Environment]::NewLine)
}

function Invoke-GuiCopyDeviceDetails {
  param(
    [Parameter(Mandatory)]
    [hashtable]$DeviceFields,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Button]$CopyButton
  )

  $SummaryText = Get-GuiDeviceDetailsSummary -DeviceFields $DeviceFields

  try {
    [System.Windows.Clipboard]::SetText($SummaryText)
  }
  catch {
    [System.Windows.MessageBox]::Show("Could not copy device details to the clipboard: $($_.Exception.Message)")
    return
  }

  $script:GuiCopyDeviceDetailsButton = $CopyButton
  $script:GuiCopyDeviceDetailsOriginalContent = $CopyButton.Content

  $CopyButton.Content = "Copied!"
  $CopyButton.IsEnabled = $false

  $Timer = New-Object System.Windows.Threading.DispatcherTimer
  $Timer.Interval = [TimeSpan]::FromMilliseconds(1400)
  $script:GuiCopyDeviceDetailsResetTimer = $Timer

  # Plain scriptblock -- deliberately NOT .GetNewClosure()'d, matching every
  # other background-runspace/UI timer handler in this app.
  $Timer.Add_Tick({
    $script:GuiCopyDeviceDetailsResetTimer.Stop()
    $script:GuiCopyDeviceDetailsButton.Content = $script:GuiCopyDeviceDetailsOriginalContent
    $script:GuiCopyDeviceDetailsButton.IsEnabled = $true
  })

  $Timer.Start()
}

function Set-GuiRenameRestartChoice {
  param(
    [Parameter(Mandatory)]
    [bool]$RestartNow,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Border]$LaterOption,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$LaterOptionText,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Border]$NowOption,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$NowOptionText
  )

  $script:GuiRenameRestartNow = $RestartNow

  if ($RestartNow) {
    $LaterOption.Background = "Transparent"
    $LaterOption.BorderBrush = "#3A3E48"
    $LaterOptionText.Foreground = "#9A9EA8"
    $LaterOptionText.FontWeight = "Normal"

    $NowOption.Background = "#2438BDF8"
    $NowOption.BorderBrush = "#38BDF8"
    $NowOptionText.Foreground = "#38BDF8"
    $NowOptionText.FontWeight = "SemiBold"
  }
  else {
    $LaterOption.Background = "#2438BDF8"
    $LaterOption.BorderBrush = "#38BDF8"
    $LaterOptionText.Foreground = "#38BDF8"
    $LaterOptionText.FontWeight = "SemiBold"

    $NowOption.Background = "Transparent"
    $NowOption.BorderBrush = "#3A3E48"
    $NowOptionText.Foreground = "#9A9EA8"
    $NowOptionText.FontWeight = "Normal"
  }
}

function Invoke-GuiComputerRename {
  param(
    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBox]$NewNameTextBox,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$CurrentNameText,

    [Parameter(Mandatory)]
    [bool]$RestartNow
  )

  $Validation = Test-DeploymentComputerName -ComputerName $NewNameTextBox.Text

  if (-not $Validation.Valid) {
    [System.Windows.MessageBox]::Show($Validation.Message)
    return
  }

  $CurrentName = Get-CurrentComputerName

  $ConfirmationPrompt = if ($RestartNow) {
    "Rename this computer from $CurrentName to $($Validation.ComputerName) and restart it immediately?`n`nThe computer will restart as soon as the rename completes. Save any open work first."
  }
  else {
    "Rename this computer from $CurrentName to $($Validation.ComputerName)?`n`nA restart is required to apply the new name. You chose to restart later, so the computer will not restart automatically."
  }

  $Confirmation = [System.Windows.MessageBox]::Show(
    $ConfirmationPrompt,
    "Confirm Rename",
    [System.Windows.MessageBoxButton]::YesNo,
    [System.Windows.MessageBoxImage]::Warning
  )

  if ($Confirmation -ne [System.Windows.MessageBoxResult]::Yes) {
    return
  }

  $RenameResult = Set-DeploymentComputerName -NewName $Validation.ComputerName -Restart:$RestartNow -Confirm:$false

  [System.Windows.MessageBox]::Show($RenameResult.Message)

  if ($RenameResult.Status -eq "Renamed") {
    $NewNameTextBox.Text = ""
  }

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

    if ($CreationResult.Status -eq "Created") {
      $UserNameTextBox.Text = ""
      $FullNameTextBox.Text = ""
    }

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
