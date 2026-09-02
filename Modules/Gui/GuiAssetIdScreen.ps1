# ============================================================
# GUI ASSET ID SCREEN
# ============================================================
# ThinkPad-only tab for editing and writing the BIOS asset-tracking fields supported by Lenovo's WinAIA utility (Modules\Windows\LenovoAssetId.ps1).

function Update-GuiAssetIdDisplay {
  # Shared by the synchronous refresh path and the background-load completion handler in GuiWindowsConfigShared.ps1. Asset ID is its own sidebar tab (NavAssetId), hidden entirely (not just disabled) on any non-ThinkPad device, per explicit instruction that this should not even appear rather than show up permanently greyed out for the common case of a non-Lenovo deployment.
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

function Invoke-GuiAssetIdSave {
  # Writes the 11 fields to Sample.txt, then launches WinAIA against it. WinAIA opens its own confirmation dialog before committing anything to BIOS -- this function cannot and does not try to click through that on the technician's behalf, only the confirmation before launching it and the result after it exits are this tool's own.
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

function Initialize-GuiAssetIdScreen {
  # FindName + click-handler wiring for this screen, called once from Show-MainWindow (GuiWindow.ps1). NavAssetId starts Visibility="Collapsed" in XAML and only becomes visible once the shared device-report load (GuiWindowsConfigShared.ps1) confirms this is a ThinkPad, so this screen's own nav item is wired here exactly like every other screen even though it may never become visible. Windows Setup, Device Details, and Asset ID share one Refresh mechanism, so the orchestrator wires all three screens' Refresh buttons itself once it has collected every screen's own controls -- this function only returns the pieces of itself that refresh needs (NavAssetId/FieldTextBoxes/RefreshButton), alongside the Nav Border/Text/Icon triple for the shared nav arrays.
  param(
    [Parameter(Mandatory)]
    [System.Windows.Window]$Window
  )

  $NavAssetId = $Window.FindName("NavAssetId")
  $NavAssetIdText = $Window.FindName("NavAssetIdText")
  $NavAssetIdIcon = $Window.FindName("NavAssetIdIcon")
  $RefreshAssetIdButton = $Window.FindName("RefreshAssetIdButton")
  $AssetOwnerNameTextBox = $Window.FindName("AssetOwnerNameTextBox")
  $AssetDepartmentTextBox = $Window.FindName("AssetDepartmentTextBox")
  $AssetLocationTextBox = $Window.FindName("AssetLocationTextBox")
  $AssetPhoneNumberTextBox = $Window.FindName("AssetPhoneNumberTextBox")
  $AssetOwnerPositionTextBox = $Window.FindName("AssetOwnerPositionTextBox")
  $AssetPurchaseDateTextBox = $Window.FindName("AssetPurchaseDateTextBox")
  $AssetLastInventoriedTextBox = $Window.FindName("AssetLastInventoriedTextBox")
  $AssetWarrantyEndTextBox = $Window.FindName("AssetWarrantyEndTextBox")
  $AssetWarrantyDurationTextBox = $Window.FindName("AssetWarrantyDurationTextBox")
  $AssetAmountTextBox = $Window.FindName("AssetAmountTextBox")
  $AssetNumberTextBox = $Window.FindName("AssetNumberTextBox")
  $SaveAssetIdButton = $Window.FindName("SaveAssetIdButton")

  # Keyed the same way Get-DeploymentAssetIdFieldNames orders them, so Update-GuiAssetIdFields/Invoke-GuiAssetIdSave can loop instead of repeating each field name by hand.
  $AssetIdFieldTextBoxes = @{
    "OWNERDATA.OWNERNAME"              = $AssetOwnerNameTextBox
    "OWNERDATA.DEPARTMENT"             = $AssetDepartmentTextBox
    "OWNERDATA.LOCATION"               = $AssetLocationTextBox
    "OWNERDATA.PHONE_NUMBER"           = $AssetPhoneNumberTextBox
    "OWNERDATA.OWNERPOSITION"          = $AssetOwnerPositionTextBox
    "USERASSETDATA.PURCHASE_DATE"      = $AssetPurchaseDateTextBox
    "USERASSETDATA.LAST_INVENTORIED"   = $AssetLastInventoriedTextBox
    "USERASSETDATA.WARRANTY_END"       = $AssetWarrantyEndTextBox
    "USERASSETDATA.WARRANTY_DURATION"  = $AssetWarrantyDurationTextBox
    "USERASSETDATA.AMOUNT"             = $AssetAmountTextBox
    "USERASSETDATA.ASSET_NUMBER"       = $AssetNumberTextBox
  }

  $script:GuiNavAssetId = $NavAssetId
  $script:GuiAssetIdToolbar = $Window.FindName("AssetIdToolbar")
  $script:GuiAssetIdScrollViewer = $Window.FindName("AssetIdScrollViewer")
  $script:GuiAssetIdFieldTextBoxes = $AssetIdFieldTextBoxes

  $SaveAssetIdButton.Add_Click({
    try {
      Invoke-GuiAssetIdSave -FieldTextBoxes $AssetIdFieldTextBoxes
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Save asset ID error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  $NavAssetId.Add_MouseLeftButtonUp({
    try {
      Switch-GuiScreen -ScreenName "Asset ID" -ActiveBorder $NavAssetId -ActiveText $NavAssetIdText -ActiveIcon $NavAssetIdIcon
    }
    catch {
      Show-GuiDialog -Title "Error" -Icon Warning -Message "Navigation error: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
    }
  })

  return @{
    NavBorder      = $NavAssetId
    NavText        = $NavAssetIdText
    NavIcon        = $NavAssetIdIcon
    RefreshButton  = $RefreshAssetIdButton
    NavAssetId     = $NavAssetId
    FieldTextBoxes = $AssetIdFieldTextBoxes
  }
}
