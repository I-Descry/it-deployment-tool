# ============================================================
# GUI WINDOWS SETUP SCREEN
# ============================================================
# Computer Rename, Local Standard User, and Power & Sleep Settings -- the three action cards on the Windows Setup tab. Device Details, Asset ID, and the shared background load these three cards' current-value refreshes depend on live in GuiDeviceDetailsScreen.ps1, GuiAssetIdScreen.ps1, and GuiWindowsConfigShared.ps1.

function New-GuiLocalUserRow {
  # Purpose-built for the narrow Local Standard User card. The Deployment Validation screen's New-GuiValidationStatusRow uses fixed-width columns sized for that screen's full-width rows; reusing it here squeezed the detail text into a sliver a few pixels wide and made it wrap letter by letter. This stacks the detail below the name instead, so it always has the full card width to wrap into.
  param(
    [Parameter(Mandatory)]
    [string]$UserName,

    [string]$DetailText
  )

  $Stack = New-Object System.Windows.Controls.StackPanel
  $Stack.Margin = "0,0,0,5"

  $TopLine = New-Object System.Windows.Controls.StackPanel
  $TopLine.Orientation = "Horizontal"

  $StatusPill = New-Object System.Windows.Controls.Border
  $StatusPill.Background = "#1934D399"
  $StatusPill.CornerRadius = "9"
  $StatusPill.Padding = "7,1"
  $StatusPill.VerticalAlignment = "Center"
  $StatusPillText = New-Object System.Windows.Controls.TextBlock
  $StatusPillText.Text = "ACTIVE"
  $StatusPillText.FontSize = 9.5
  $StatusPillText.FontWeight = "Bold"
  $StatusPillText.Foreground = "#34D399"
  $StatusPill.Child = $StatusPillText
  $TopLine.Children.Add($StatusPill) | Out-Null

  $NameText = New-Object System.Windows.Controls.TextBlock
  $NameText.Text = $UserName
  $NameText.FontSize = 12.5
  $NameText.FontWeight = "SemiBold"
  $NameText.Foreground = "#E8E9EC"
  $NameText.TextTrimming = "CharacterEllipsis"
  $NameText.VerticalAlignment = "Center"
  $NameText.Margin = "8,0,0,0"
  $TopLine.Children.Add($NameText) | Out-Null

  $Stack.Children.Add($TopLine) | Out-Null

  if (-not [string]::IsNullOrWhiteSpace($DetailText) -and $DetailText -ne $UserName) {
    $DetailBlock = New-Object System.Windows.Controls.TextBlock
    $DetailBlock.Text = $DetailText
    $DetailBlock.FontSize = 11
    $DetailBlock.Foreground = "#6B6F79"
    $DetailBlock.TextWrapping = "Wrap"
    $DetailBlock.Margin = "0,2,0,0"
    $Stack.Children.Add($DetailBlock) | Out-Null
  }

  return $Stack
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
    $Row = New-GuiLocalUserRow -UserName $User.Name -DetailText $DetailText
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
    Show-GuiDialog -Title "Invalid Name" -Icon Warning -Message $Validation.Message
    return
  }

  $CurrentName = Get-CurrentComputerName

  $ConfirmationPrompt = if ($RestartNow) {
    "Rename this computer from $CurrentName to $($Validation.ComputerName) and restart it immediately?`n`nThe computer will restart as soon as the rename completes. Save any open work first."
  }
  else {
    "Rename this computer from $CurrentName to $($Validation.ComputerName)?`n`nA restart is required to apply the new name. You chose to restart later, so the computer will not restart automatically."
  }

  $Confirmation = Show-GuiDialog -Title "Confirm Rename" -Icon Warning -Buttons YesNo -Message $ConfirmationPrompt

  if ($Confirmation -ne "Yes") {
    return
  }

  $RenameResult = Set-DeploymentComputerName -NewName $Validation.ComputerName -Restart:$RestartNow -Confirm:$false

  Show-GuiResultDialog -Result $RenameResult -SuccessTitle "Computer Renamed"

  if ($RenameResult.Status -eq "Renamed") {
    $NewNameTextBox.Text = ""
  }

  Update-GuiWindowsConfigCurrentName -CurrentNameText $CurrentNameText
}

function Set-GuiCreateUserPasswordChoice {
  param(
    [Parameter(Mandatory)]
    [bool]$NoPassword,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Border]$SetOption,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$SetOptionText,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Border]$NoPasswordOption,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$NoPasswordOptionText,

    [Parameter(Mandatory)]
    [System.Windows.Controls.StackPanel]$PasswordFieldsPanel,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Border]$NoticeText,

    [Parameter(Mandatory)]
    [System.Windows.Controls.PasswordBox]$PasswordBox,

    [Parameter(Mandatory)]
    [System.Windows.Controls.PasswordBox]$ConfirmPasswordBox
  )

  $script:GuiCreateUserNoPassword = $NoPassword

  if ($NoPassword) {
    $SetOption.Background = "Transparent"
    $SetOption.BorderBrush = "#3A3E48"
    $SetOptionText.Foreground = "#9A9EA8"
    $SetOptionText.FontWeight = "Normal"

    $NoPasswordOption.Background = "#2438BDF8"
    $NoPasswordOption.BorderBrush = "#38BDF8"
    $NoPasswordOptionText.Foreground = "#38BDF8"
    $NoPasswordOptionText.FontWeight = "SemiBold"

    $PasswordFieldsPanel.Visibility = "Collapsed"
    $NoticeText.Visibility = "Visible"
    $PasswordBox.Clear()
    $ConfirmPasswordBox.Clear()
  }
  else {
    $SetOption.Background = "#2438BDF8"
    $SetOption.BorderBrush = "#38BDF8"
    $SetOptionText.Foreground = "#38BDF8"
    $SetOptionText.FontWeight = "SemiBold"

    $NoPasswordOption.Background = "Transparent"
    $NoPasswordOption.BorderBrush = "#3A3E48"
    $NoPasswordOptionText.Foreground = "#9A9EA8"
    $NoPasswordOptionText.FontWeight = "Normal"

    $PasswordFieldsPanel.Visibility = "Visible"
    $NoticeText.Visibility = "Collapsed"
  }
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
    [System.Windows.Controls.StackPanel]$ListPanel,

    [Parameter(Mandatory)]
    [bool]$NoPassword
  )

  try {
    $Validation = Test-DeploymentLocalUserName -UserName $UserNameTextBox.Text

    if (-not $Validation.Valid) {
      Show-GuiDialog -Title "Invalid Username" -Icon Warning -Message $Validation.Message
      return
    }

    $UserName = $Validation.UserName

    if (Test-LocalUserExists -UserName $UserName) {
      Show-GuiDialog -Title "User Exists" -Icon Warning -Message "The local user already exists."
      return
    }

    if (-not $NoPassword) {
      if ($PasswordBox.SecurePassword.Length -eq 0) {
        Show-GuiDialog -Title "Password Required" -Icon Warning -Message "The password cannot be empty. Choose No Password above if you want to create this account without one."
        return
      }

      if (-not (Test-SecurePasswordMatch -Password $PasswordBox.SecurePassword -Confirmation $ConfirmPasswordBox.SecurePassword)) {
        Show-GuiDialog -Title "Password Mismatch" -Icon Warning -Message "The passwords do not match."
        return
      }
    }

    $FullName = $FullNameTextBox.Text

    $ConfirmationMessage = if ([string]::IsNullOrWhiteSpace($FullName)) {
      "Create local standard user '$UserName'?"
    }
    else {
      "Create local standard user '$UserName' ($FullName)?"
    }

    if ($NoPassword) {
      $ConfirmationMessage += "`n`nThis account will be created with no password."
    }

    $Confirmation = Show-GuiDialog -Title "Confirm Create User" -Icon Warning -Buttons YesNo -Message $ConfirmationMessage

    if ($Confirmation -ne "Yes") {
      return
    }

    $CreationResult = New-DeploymentLocalStandardUser -UserName $UserName -Password $PasswordBox.SecurePassword -NoPassword:$NoPassword -FullName $FullName -Confirm:$false

    Show-GuiResultDialog -Result $CreationResult -SuccessTitle "User Created"

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
    Show-GuiDialog -Title "Invalid Value" -Icon Warning -Message $PluggedInTest.Message
    return
  }

  $BatteryTest = Test-SleepTimeoutMinutes -Value $BatteryMinutesTextBox.Text -SettingName "Battery sleep timeout"

  if (-not $BatteryTest.Valid) {
    Show-GuiDialog -Title "Invalid Value" -Icon Warning -Message $BatteryTest.Message
    return
  }

  $Confirmation = Show-GuiDialog -Title "Confirm Power Settings" -Icon Warning -Buttons YesNo -Message "Set plugged-in sleep to $($PluggedInTest.Minutes) minutes and battery sleep to $($BatteryTest.Minutes) minutes?"

  if ($Confirmation -ne "Yes") {
    return
  }

  $Result = Set-DeploymentSleepTimeouts -PluggedInMinutes $PluggedInTest.Minutes -BatteryMinutes $BatteryTest.Minutes -Confirm:$false

  Show-GuiResultDialog -Result $Result -SuccessTitle "Power Settings Applied"

  Update-GuiWindowsConfigPowerCurrentValues -CurrentPluggedInText $CurrentPluggedInText -CurrentBatteryText $CurrentBatteryText
}

function Initialize-GuiWindowsSetupScreen {
  # FindName + click-handler wiring for this screen, called once from Show-MainWindow (GuiWindow.ps1). Windows Setup, Device Details, and Asset ID share one Refresh mechanism (Invoke-GuiWindowsConfigurationRefresh, GuiWindowsConfigShared.ps1), so the orchestrator wires all three screens' Refresh buttons itself once it has collected every screen's own controls -- this function only returns the pieces of itself that refresh needs (CurrentNameText/LocalUsersListPanel/CurrentPluggedInText/CurrentBatteryText/RefreshButton), alongside the Nav Border/Text/Icon triple for the shared nav arrays.
  param(
    [Parameter(Mandatory)]
    [System.Windows.Window]$Window
  )

  $CurrentComputerNameText = $Window.FindName("CurrentComputerNameText")
  $NewComputerNameTextBox = $Window.FindName("NewComputerNameTextBox")
  $RestartLaterOption = $Window.FindName("RestartLaterOption")
  $RestartLaterOptionText = $Window.FindName("RestartLaterOptionText")
  $RestartNowOption = $Window.FindName("RestartNowOption")
  $RestartNowOptionText = $Window.FindName("RestartNowOptionText")
  $RenameComputerButton = $Window.FindName("RenameComputerButton")
  $LocalUsersListPanel = $Window.FindName("LocalUsersListPanel")
  $NewUserNameTextBox = $Window.FindName("NewUserNameTextBox")
  $NewUserFullNameTextBox = $Window.FindName("NewUserFullNameTextBox")
  $SetPasswordOption = $Window.FindName("SetPasswordOption")
  $SetPasswordOptionText = $Window.FindName("SetPasswordOptionText")
  $NoPasswordOption = $Window.FindName("NoPasswordOption")
  $NoPasswordOptionText = $Window.FindName("NoPasswordOptionText")
  $NewUserPasswordFieldsPanel = $Window.FindName("NewUserPasswordFieldsPanel")
  $NoPasswordNoticeBox = $Window.FindName("NoPasswordNoticeBox")
  $NewUserPasswordBox = $Window.FindName("NewUserPasswordBox")
  $NewUserConfirmPasswordBox = $Window.FindName("NewUserConfirmPasswordBox")
  $CreateUserButton = $Window.FindName("CreateUserButton")
  $CurrentPluggedInText = $Window.FindName("CurrentPluggedInText")
  $CurrentBatteryText = $Window.FindName("CurrentBatteryText")
  $PluggedInMinutesTextBox = $Window.FindName("PluggedInMinutesTextBox")
  $BatteryMinutesTextBox = $Window.FindName("BatteryMinutesTextBox")
  $ApplyPowerSettingsButton = $Window.FindName("ApplyPowerSettingsButton")
  $RefreshWindowsSetupButton = $Window.FindName("RefreshWindowsSetupButton")
  $NavWindowsSetup = $Window.FindName("NavWindowsSetup")
  $NavWindowsSetupText = $Window.FindName("NavWindowsSetupText")
  $NavWindowsSetupIcon = $Window.FindName("NavWindowsSetupIcon")

  $script:GuiWindowsSetupToolbar = $Window.FindName("WindowsSetupToolbar")
  $script:GuiWindowsSetupScrollViewer = $Window.FindName("WindowsSetupScrollViewer")
  $script:GuiCurrentComputerNameText = $CurrentComputerNameText
  $script:GuiLocalUsersListPanel = $LocalUsersListPanel
  $script:GuiCurrentPluggedInText = $CurrentPluggedInText
  $script:GuiCurrentBatteryText = $CurrentBatteryText

  $InitialTimeouts = Get-CurrentSleepTimeoutMinutes
  $PluggedInMinutesTextBox.Text = [string]$InitialTimeouts.PluggedInMinutes
  $BatteryMinutesTextBox.Text = [string]$InitialTimeouts.BatteryMinutes

  # Defaults to Later (today's existing rename behavior) -- Restart Now is always an explicit choice, never the default, since it restarts the machine immediately.
  $script:GuiRenameRestartNow = $false

  $RestartLaterOption.Add_MouseLeftButtonUp({
    try {
      Set-GuiRenameRestartChoice -RestartNow $false -LaterOption $RestartLaterOption -LaterOptionText $RestartLaterOptionText -NowOption $RestartNowOption -NowOptionText $RestartNowOptionText
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Restart choice error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $RestartNowOption.Add_MouseLeftButtonUp({
    try {
      Set-GuiRenameRestartChoice -RestartNow $true -LaterOption $RestartLaterOption -LaterOptionText $RestartLaterOptionText -NowOption $RestartNowOption -NowOptionText $RestartNowOptionText
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Restart choice error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $RenameComputerButton.Add_Click({
    try {
      Invoke-GuiComputerRename -NewNameTextBox $NewComputerNameTextBox -CurrentNameText $CurrentComputerNameText -RestartNow $script:GuiRenameRestartNow
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Rename error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  # Defaults to Set Password (today's existing behavior) -- No Password is always an explicit choice, never the default, since a blank-password local account is an unusual security posture.
  $script:GuiCreateUserNoPassword = $false

  $SetPasswordOption.Add_MouseLeftButtonUp({
    try {
      Set-GuiCreateUserPasswordChoice -NoPassword $false -SetOption $SetPasswordOption -SetOptionText $SetPasswordOptionText -NoPasswordOption $NoPasswordOption -NoPasswordOptionText $NoPasswordOptionText -PasswordFieldsPanel $NewUserPasswordFieldsPanel -NoticeText $NoPasswordNoticeBox -PasswordBox $NewUserPasswordBox -ConfirmPasswordBox $NewUserConfirmPasswordBox
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Password choice error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $NoPasswordOption.Add_MouseLeftButtonUp({
    try {
      Set-GuiCreateUserPasswordChoice -NoPassword $true -SetOption $SetPasswordOption -SetOptionText $SetPasswordOptionText -NoPasswordOption $NoPasswordOption -NoPasswordOptionText $NoPasswordOptionText -PasswordFieldsPanel $NewUserPasswordFieldsPanel -NoticeText $NoPasswordNoticeBox -PasswordBox $NewUserPasswordBox -ConfirmPasswordBox $NewUserConfirmPasswordBox
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Password choice error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $CreateUserButton.Add_Click({
    try {
      Invoke-GuiLocalUserCreation -UserNameTextBox $NewUserNameTextBox -FullNameTextBox $NewUserFullNameTextBox -PasswordBox $NewUserPasswordBox -ConfirmPasswordBox $NewUserConfirmPasswordBox -ListPanel $LocalUsersListPanel -NoPassword $script:GuiCreateUserNoPassword
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Create user error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $ApplyPowerSettingsButton.Add_Click({
    try {
      Invoke-GuiPowerSettingsApply -PluggedInMinutesTextBox $PluggedInMinutesTextBox -BatteryMinutesTextBox $BatteryMinutesTextBox -CurrentPluggedInText $CurrentPluggedInText -CurrentBatteryText $CurrentBatteryText
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Apply power settings error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $NavWindowsSetup.Add_MouseLeftButtonUp({
    try {
      Switch-GuiScreen -ScreenName "Windows Setup" -ActiveBorder $NavWindowsSetup -ActiveText $NavWindowsSetupText -ActiveIcon $NavWindowsSetupIcon
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Navigation error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  return @{
    NavBorder            = $NavWindowsSetup
    NavText              = $NavWindowsSetupText
    NavIcon              = $NavWindowsSetupIcon
    RefreshButton        = $RefreshWindowsSetupButton
    CurrentNameText      = $CurrentComputerNameText
    LocalUsersListPanel  = $LocalUsersListPanel
    CurrentPluggedInText = $CurrentPluggedInText
    CurrentBatteryText   = $CurrentBatteryText
  }
}
