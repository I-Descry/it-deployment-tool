# ============================================================
# GUI COMPLETION MODAL
# ============================================================
# Generic install/uninstall/cleanup completion reporting, shared across every screen that runs a queue or a batch destructive action (Applications' install/uninstall queues, Temp Cleanup) -- split out of GuiApplicationsScreen.ps1 since it stopped being Applications-specific the moment Temp Cleanup started reusing it.

$script:GuiCompletionModalStatusColors = @{
  Installed   = "#34D399"
  Uninstalled = "#34D399"
  Skipped     = "#9A9EA8"
  Blocked     = "#FBBF24"
  Failed      = "#F2555A"
  "Not Found" = "#F2555A"
  Cancelled   = "#9A9EA8"
}

function Show-GuiCompletionModal {
  param(
    [Parameter(Mandatory)]
    [System.Windows.Controls.Border]$Overlay,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Canvas]$IconSuccess,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Canvas]$IconWarning,

    [Parameter(Mandatory)]
    [System.Windows.Controls.TextBlock]$TitleText,

    [Parameter(Mandatory)]
    [System.Windows.Controls.StackPanel]$CountsPanel,

    [Parameter(Mandatory)]
    [System.Windows.Controls.Border]$DetailsCard,

    [Parameter(Mandatory)]
    [System.Windows.Controls.StackPanel]$DetailsPanel,

    [Parameter(Mandatory)]
    [string]$Title,

    [Parameter(Mandatory)]
    [System.Collections.Specialized.OrderedDictionary]$Counts,

    [string[]]$FailureMessages = @()
  )

  $TitleText.Text = $Title

  $HasFailures = ($FailureMessages.Count -gt 0)
  $IconSuccess.Visibility = if ($HasFailures) { "Collapsed" } else { "Visible" }
  $IconWarning.Visibility = if ($HasFailures) { "Visible" } else { "Collapsed" }

  $CountsPanel.Children.Clear()

  foreach ($Entry in $Counts.GetEnumerator()) {
    $Color = $script:GuiCompletionModalStatusColors[$Entry.Key]

    if ([string]::IsNullOrWhiteSpace($Color)) {
      $Color = "#9A9EA8"
    }

    $Badge = New-Object System.Windows.Controls.Border
    $Badge.CornerRadius = "8"
    $Badge.Padding = "10,5"
    $Badge.Margin = "0,0,8,8"
    $Badge.Background = "#1A" + $Color.TrimStart("#")

    $BadgeText = New-Object System.Windows.Controls.TextBlock
    $BadgeText.Text = "$($Entry.Value) $($Entry.Key)"
    $BadgeText.FontSize = 11.5
    $BadgeText.FontWeight = "SemiBold"
    $BadgeText.Foreground = $Color
    $Badge.Child = $BadgeText

    $CountsPanel.Children.Add($Badge) | Out-Null
  }

  $DetailsPanel.Children.Clear()

  if ($HasFailures) {
    $DetailsCard.Visibility = "Visible"

    foreach ($Message in $FailureMessages) {
      $DetailText = New-Object System.Windows.Controls.TextBlock
      $DetailText.Text = "- $Message"
      $DetailText.Foreground = "#E8E9EC"
      $DetailText.FontSize = 11.5
      $DetailText.TextWrapping = "Wrap"
      $DetailText.Margin = "0,0,0,6"
      $DetailsPanel.Children.Add($DetailText) | Out-Null
    }
  }
  else {
    $DetailsCard.Visibility = "Collapsed"
  }

  # Stored so CompletionModalCopyButton's click handler can copy exactly what this modal is currently showing.
  $script:GuiCompletionModalSummaryText = Get-GuiCompletionSummary -Title $Title -Counts $Counts -FailureMessages $FailureMessages

  $Overlay.Visibility = "Visible"
}

function Get-GuiCompletionSummary {
  param(
    [Parameter(Mandatory)]
    [string]$Title,

    [Parameter(Mandatory)]
    [System.Collections.Specialized.OrderedDictionary]$Counts,

    [string[]]$FailureMessages = @()
  )

  $Lines = @($Title, "")

  foreach ($Entry in $Counts.GetEnumerator()) {
    $Lines += "{0}: {1}" -f $Entry.Key, $Entry.Value
  }

  if ($FailureMessages.Count -gt 0) {
    $Lines += ""
    $Lines += "Details:"

    foreach ($Message in $FailureMessages) {
      $Lines += "- $Message"
    }
  }

  return ($Lines -join [Environment]::NewLine)
}

function Invoke-GuiCopyCompletionSummary {
  param(
    [Parameter(Mandatory)]
    [System.Windows.Controls.Button]$CopyButton
  )

  try {
    [System.Windows.Clipboard]::SetText($script:GuiCompletionModalSummaryText)
  }
  catch {
    Show-GuiDialog -Title "Error" -Icon Warning -Message "Could not copy the results to the clipboard: $($_.Exception.Message)"
    return
  }

  $script:GuiCopyCompletionButton = $CopyButton
  $script:GuiCopyCompletionOriginalContent = $CopyButton.Content

  $CopyButton.Content = "Copied!"
  $CopyButton.IsEnabled = $false

  $Timer = New-Object System.Windows.Threading.DispatcherTimer
  $Timer.Interval = [TimeSpan]::FromMilliseconds(1400)
  $script:GuiCopyCompletionResetTimer = $Timer

  # Plain scriptblock -- deliberately NOT .GetNewClosure()'d, matching every other background-runspace/UI timer handler in this app.
  $Timer.Add_Tick({
    $script:GuiCopyCompletionResetTimer.Stop()
    $script:GuiCopyCompletionButton.Content = $script:GuiCopyCompletionOriginalContent
    $script:GuiCopyCompletionButton.IsEnabled = $true
  })

  $Timer.Start()
}
