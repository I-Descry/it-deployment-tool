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
