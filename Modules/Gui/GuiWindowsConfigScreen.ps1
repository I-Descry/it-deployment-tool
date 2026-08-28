# ============================================================
# GUI WINDOWS CONFIGURATION SCREEN
# ============================================================

function New-GuiLocalUserRow {
  # Purpose-built for the narrow Local Standard User card. The Deployment
  # Validation screen's New-GuiValidationStatusRow uses fixed-width columns
  # sized for that screen's full-width rows; reusing it here squeezed the
  # detail text into a sliver a few pixels wide and made it wrap letter by
  # letter. This stacks the detail below the name instead, so it always has
  # the full card width to wrap into.
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
  $Fields.BiosVersion.Text = $Report.BiosVersion
  $Fields.AssetTag.Text = $Report.AssetTag
  $Fields.NetworkType.Text = $Report.NetworkType
  $Fields.IPAddress.Text = $Report.IPAddress
  $Fields.MacAddress.Text = $Report.MacAddress
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

  # Not Activated is a real, worth-flagging problem on a deployment device
  # (matching how Administrator uses red for "no"), while Unknown just means
  # the licensing query itself failed and is not itself a bad state.
  $Fields.ActivationStatus.Text = $Report.ActivationStatus
  $Fields.ActivationStatus.Foreground = switch ($Report.ActivationStatus) {
    "Licensed"      { "#34D399" }
    "Not Activated" { "#F2555A" }
    default         { "#6B6F79" }
  }
  $Fields.ActivationStatusPill.Background = switch ($Report.ActivationStatus) {
    "Licensed"      { "#1934D399" }
    "Not Activated" { "#1AF2555A" }
    default         { "#23262E" }
  }

  $Fields.LastUpdateInstalled.Text = $Report.LastUpdateInstalled

  $Fields.SecureBootStatus.Text = $Report.SecureBootStatus
  $Fields.SecureBootStatus.Foreground = if ($Report.SecureBootStatus -eq "On") { "#34D399" } else { "#6B6F79" }
  $Fields.SecureBootStatusPill.Background = if ($Report.SecureBootStatus -eq "On") { "#1934D399" } else { "#23262E" }

  $Fields.BatteryHealth.Text = $Report.BatteryHealth
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

function Update-GuiAssetIdDisplay {
  # Shared by the synchronous refresh path and the background-load completion
  # handler below. Asset ID is its own sidebar tab (NavAssetId), hidden
  # entirely (not just disabled) on any non-ThinkPad device, per explicit
  # instruction that this should not even appear rather than show up
  # permanently greyed out for the common case of a non-Lenovo deployment.
  param(
    [Parameter(Mandatory)]
    [System.Windows.Controls.Border]$NavAssetId,

    [Parameter(Mandatory)]
    [hashtable]$FieldTextBoxes,

    [Parameter(Mandatory)]
    [bool]$IsThinkPad,

    [hashtable]$Fields
  )

  if (-not $IsThinkPad) {
    $NavAssetId.Visibility = "Collapsed"
    return
  }

  $NavAssetId.Visibility = "Visible"

  if ($null -eq $Fields) {
    return
  }

  foreach ($Key in $FieldTextBoxes.Keys) {
    if ($Fields.ContainsKey($Key)) {
      $FieldTextBoxes[$Key].Text = [string]$Fields[$Key]
    }
  }
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
    [System.Windows.Controls.TextBlock]$CurrentBatteryText,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Border]$NavAssetId,

    [Parameter(Mandatory)]
    [hashtable]$AssetIdFieldTextBoxes
  )

  Update-GuiWindowsConfigDeviceInfo -Fields $DeviceFields
  Update-GuiWindowsConfigCurrentName -CurrentNameText $CurrentNameText
  Update-GuiWindowsConfigLocalUsersList -ListPanel $LocalUsersListPanel
  Update-GuiWindowsConfigPowerCurrentValues -CurrentPluggedInText $CurrentPluggedInText -CurrentBatteryText $CurrentBatteryText

  $IsThinkPad = [bool](Get-WindowsConfigurationIdentity).IsThinkPad
  $AssetFields = if ($IsThinkPad) { Get-DeploymentAssetIdFields } else { $null }
  Update-GuiAssetIdDisplay -NavAssetId $NavAssetId -FieldTextBoxes $AssetIdFieldTextBoxes -IsThinkPad $IsThinkPad -Fields $AssetFields
}

function Invoke-GuiAssetIdSave {
  # Writes the 11 fields to Sample.txt, then launches WinAIA against it.
  # WinAIA opens its own confirmation dialog before committing anything to
  # BIOS -- this function cannot and does not try to click through that on
  # the technician's behalf, only the confirmation before launching it and
  # the result after it exits are this tool's own.
  param(
    [Parameter(Mandatory)]
    [hashtable]$FieldTextBoxes
  )

  $Fields = @{}

  foreach ($Key in $FieldTextBoxes.Keys) {
    $Fields[$Key] = $FieldTextBoxes[$Key].Text
  }

  $Confirmation = Show-GuiDialog -Title "Confirm Asset ID Save" -Icon Warning -Buttons YesNo -Message "Save these values and launch WinAIA to write them to BIOS?`n`nWinAIA will open its own confirmation window -- review the changes there and confirm to finish."

  if ($Confirmation -ne "Yes") {
    return
  }

  try {
    Set-DeploymentAssetIdFields -Fields $Fields | Out-Null
  }
  catch {
    Show-GuiDialog -Title "Error" -Icon Warning -Message "Could not save Sample.txt: $($_.Exception.Message)"
    return
  }

  $Result = Invoke-DeploymentAssetIdWrite
  Show-GuiResultDialog -Result $Result -SuccessTitle "Asset ID Saved"
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

    # Windows Setup, Device Details, and Asset ID each have their own Refresh
    # button over this one shared load, so all three are disabled for its duration.
    [Parameter(Mandatory)]
    [System.Windows.Controls.Button[]]$RefreshButtons,

    [Parameter(Mandatory)]
    [System.Windows.Controls.ScrollViewer]$ScrollViewer,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Border]$NavAssetId,

    [Parameter(Mandatory)]
    [hashtable]$AssetIdFieldTextBoxes
  )

  foreach ($RefreshButton in $RefreshButtons) {
    $RefreshButton.IsEnabled = $false
  }

  # Hides the screen for the duration of the load instead of leaving it fully
  # visible with stale "-" placeholders and the ThinkPad-only Asset ID card
  # missing (indistinguishable from "this isn't a ThinkPad" until the load
  # finishes). Start-GuiFadeIn below reveals it once, fully populated, rather
  # than flashing hidden-then-visible at the end on top of already-visible
  # stale content.
  $ScrollViewer.Opacity = 0

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
      "Windows\LenovoAssetId.ps1"
    )

    foreach ($ModulePath in $ModulePaths) {
      . (Join-Path $RootPath "Modules\$ModulePath")
    }

    $script:ITDeploymentToolRoot = $RootPath

    $Report = Get-WindowsConfigurationReport
    $CurrentName = Get-CurrentComputerName
    $LocalUsers = @(Get-DeploymentLocalStandardUsers)
    $Timeouts = Get-CurrentSleepTimeoutMinutes
    $AssetFields = if ($Report.IsThinkPad) { Get-DeploymentAssetIdFields } else { $null }

    return [PSCustomObject]@{
      Report      = $Report
      CurrentName = $CurrentName
      LocalUsers  = $LocalUsers
      Timeouts    = $Timeouts
      AssetFields = $AssetFields
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
  $script:GuiWindowsConfigLoadNavAssetId = $NavAssetId
  $script:GuiWindowsConfigLoadAssetIdFieldTextBoxes = $AssetIdFieldTextBoxes

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
      $Fields.BiosVersion.Text = $Report.BiosVersion
      $Fields.AssetTag.Text = $Report.AssetTag
      $Fields.NetworkType.Text = $Report.NetworkType
      $Fields.IPAddress.Text = $Report.IPAddress
      $Fields.MacAddress.Text = $Report.MacAddress
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
      $Fields.ActivationStatus.Text = $Report.ActivationStatus
      $Fields.ActivationStatus.Foreground = switch ($Report.ActivationStatus) {
        "Licensed"      { "#34D399" }
        "Not Activated" { "#F2555A" }
        default         { "#6B6F79" }
      }
      $Fields.ActivationStatusPill.Background = switch ($Report.ActivationStatus) {
        "Licensed"      { "#1934D399" }
        "Not Activated" { "#1AF2555A" }
        default         { "#23262E" }
      }
      $Fields.LastUpdateInstalled.Text = $Report.LastUpdateInstalled
      $Fields.SecureBootStatus.Text = $Report.SecureBootStatus
      $Fields.SecureBootStatus.Foreground = if ($Report.SecureBootStatus -eq "On") { "#34D399" } else { "#6B6F79" }
      $Fields.SecureBootStatusPill.Background = if ($Report.SecureBootStatus -eq "On") { "#1934D399" } else { "#23262E" }
      $Fields.BatteryHealth.Text = $Report.BatteryHealth

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
          $Row = New-GuiLocalUserRow -UserName $User.Name -DetailText $DetailText
          $ListPanel.Children.Add($Row) | Out-Null
        }
      }

      $script:GuiWindowsConfigLoadCurrentPluggedInText.Text = Convert-SleepTimeoutMinutesToText -Minutes $Result.Timeouts.PluggedInMinutes
      $script:GuiWindowsConfigLoadCurrentBatteryText.Text = Convert-SleepTimeoutMinutesToText -Minutes $Result.Timeouts.BatteryMinutes

      Update-GuiAssetIdDisplay -NavAssetId $script:GuiWindowsConfigLoadNavAssetId -FieldTextBoxes $script:GuiWindowsConfigLoadAssetIdFieldTextBoxes -IsThinkPad $Report.IsThinkPad -Fields $Result.AssetFields

      Start-GuiFadeIn -Element $script:GuiWindowsConfigLoadScrollViewer
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Device information load error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
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
    "BIOS Version      : {0}" -f $DeviceFields.BiosVersion.Text
    "Asset Tag         : {0}" -f $DeviceFields.AssetTag.Text
    "Network Type      : {0}" -f $DeviceFields.NetworkType.Text
    "IP Address        : {0}" -f $DeviceFields.IPAddress.Text
    "MAC Address       : {0}" -f $DeviceFields.MacAddress.Text
    "Domain/Workgroup  : {0}" -f $DeviceFields.DomainWorkgroup.Text
    "OS Edition        : {0}" -f $DeviceFields.OSEdition.Text
    "OS Version        : {0}" -f $DeviceFields.OSVersion.Text
    "Build Number      : {0}" -f $DeviceFields.OSBuildNumber.Text
    "Architecture      : {0}" -f $DeviceFields.OSArchitecture.Text
    "Activation        : {0}" -f $DeviceFields.ActivationStatus.Text
    "Last Update       : {0}" -f $DeviceFields.LastUpdateInstalled.Text
    "Logged User       : {0}" -f $DeviceFields.LoggedUser.Text
    "Administrator     : {0}" -f $DeviceFields.AdminStatus.Text
    "Active Power Plan : {0}" -f $DeviceFields.PowerPlan.Text
    "Sleep Settings    : {0}" -f $DeviceFields.Sleep.Text
    "Processor         : {0}" -f $DeviceFields.Processor.Text
    "Memory            : {0}" -f $DeviceFields.Memory.Text
    "Storage           : {0}" -f $DeviceFields.Storage.Text
    "TPM               : {0}" -f $DeviceFields.TpmStatus.Text
    "Secure Boot       : {0}" -f $DeviceFields.SecureBootStatus.Text
    "Battery Health    : {0}" -f $DeviceFields.BatteryHealth.Text
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
    Show-GuiDialog -Title "Error" -Icon Warning -Message "Could not copy device details to the clipboard: $($_.Exception.Message)"
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

function Show-GuiResultDialog {
  # Shared by every action on this screen that returns the common
  # {Status, Message} shape (Set-DeploymentComputerName, New-DeploymentLocalStandardUser,
  # Set-DeploymentSleepTimeouts): maps the result's Status to the matching
  # dialog icon and title, rather than repeating that mapping at each call site.
  param(
    [Parameter(Mandatory)]
    [PSCustomObject]$Result,

    [Parameter(Mandatory)]
    [string]$SuccessTitle
  )

  $Icon = switch ($Result.Status) {
    "Failed" { "Warning" }
    "Skipped" { "Info" }
    "Preview Only" { "Info" }
    default { "Success" }
  }

  $Title = if ($Result.Status -eq "Failed") { "Error" } else { $SuccessTitle }

  Show-GuiDialog -Title $Title -Icon $Icon -Message $Result.Message
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
