# ============================================================
# GUI WINDOWS CONFIGURATION - SHARED DEVICE REPORT
# ============================================================
# Windows Setup, Device Details, and Asset ID are three separate sidebar tabs fed by one shared device report (CIM/BIOS/powercfg/Sample.txt), so whichever of the three is opened first performs the load and the others reuse it. This file holds that shared load/refresh plumbing and the one dialog-result helper (Show-GuiResultDialog) generic enough to be used by more than one of those three screens; each screen's own rendering and action logic lives in its own file (GuiWindowsSetupScreen.ps1, GuiDeviceDetailsScreen.ps1, GuiAssetIdScreen.ps1).

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

  # Not Activated is a real, worth-flagging problem on a deployment device (matching how Administrator uses red for "no"), while Unknown just means the licensing query itself failed and is not itself a bad state.
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
  $Fields.Uptime.Text = $Report.Uptime

  $Fields.SecureBootStatus.Text = $Report.SecureBootStatus
  $Fields.SecureBootStatus.Foreground = if ($Report.SecureBootStatus -eq "On") { "#34D399" } else { "#6B6F79" }
  $Fields.SecureBootStatusPill.Background = if ($Report.SecureBootStatus -eq "On") { "#1934D399" } else { "#23262E" }

  $Fields.BatteryHealth.Text = $Report.BatteryHealth
  $Fields.AntivirusStatus.Text = $Report.AntivirusStatus

  $Fields.FirewallStatus.Text = $Report.FirewallStatus
  $Fields.FirewallStatus.Foreground = if ($Report.FirewallStatus -eq "On") { "#34D399" } else { "#6B6F79" }
  $Fields.FirewallStatusPill.Background = if ($Report.FirewallStatus -eq "On") { "#1934D399" } else { "#23262E" }
}

function Show-GuiResultDialog {
  # Shared by every action across these screens that returns the common {Status, Message} shape (Set-DeploymentComputerName, New-DeploymentLocalStandardUser, Set-DeploymentSleepTimeouts, Invoke-DeploymentAssetIdWrite): maps the result's Status to the matching dialog icon and title, rather than repeating that mapping at each call site.
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

    # Windows Setup, Device Details, and Asset ID each have their own Refresh button over this one shared load, so all three are disabled for its duration.
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

  # Hides the screen for the duration of the load instead of leaving it fully visible with stale "-" placeholders and the ThinkPad-only Asset ID card missing (indistinguishable from "this isn't a ThinkPad" until the load finishes). Start-GuiFadeIn below reveals it once, fully populated, rather than flashing hidden-then-visible at the end on top of already-visible stale content.
  $ScrollViewer.Opacity = 0

  $RootPath = $script:ITDeploymentToolRoot

  # Used only for the screen's first load (see Switch-GuiScreen), where the CIM/BIOS/powercfg queries are guaranteed to be a real, un-cached cost. The Refresh button keeps using the synchronous Invoke-GuiWindowsConfigurationRefresh below, since by then the identity cache in Get-WindowsConfigurationIdentity (WindowsConfiguration.ps1) is already warm in the main runspace and that path is already fast (~60ms) -- backgrounding it would add complexity for no perceptible benefit. A fresh background runspace has its own empty cache, so this path always pays the full first-query cost.
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

  # Plain scriptblock -- deliberately NOT .GetNewClosure()'d, matching every other background-runspace timer handler in this app.
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
      $Fields.Uptime.Text = $Report.Uptime
      $Fields.SecureBootStatus.Text = $Report.SecureBootStatus
      $Fields.SecureBootStatus.Foreground = if ($Report.SecureBootStatus -eq "On") { "#34D399" } else { "#6B6F79" }
      $Fields.SecureBootStatusPill.Background = if ($Report.SecureBootStatus -eq "On") { "#1934D399" } else { "#23262E" }
      $Fields.BatteryHealth.Text = $Report.BatteryHealth
      $Fields.AntivirusStatus.Text = $Report.AntivirusStatus
      $Fields.FirewallStatus.Text = $Report.FirewallStatus
      $Fields.FirewallStatus.Foreground = if ($Report.FirewallStatus -eq "On") { "#34D399" } else { "#6B6F79" }
      $Fields.FirewallStatusPill.Background = if ($Report.FirewallStatus -eq "On") { "#1934D399" } else { "#23262E" }

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
