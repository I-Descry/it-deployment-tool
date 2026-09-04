# ============================================================
# GUI MODE SELECTION
# ============================================================
# The first thing shown in GUI mode, before Show-MainWindow ever loads -- lets a technician choose IT (unchanged, full tool) or Employee (Applications only, catalog restricted to a fixed set of categories; see Get-VisibleApplications in ApplicationCatalog.ps1) for this session. Reuses Show-GuiDialog's own no-owner layout (centered, dark overlay + rounded card) and New-GuiDialogButton (GuiDialog.ps1) rather than reinventing styling, since $script:GuiMainWindow does not exist yet at this point in startup. Both choice buttons are built inline in this function's own body (not a shared per-button helper function), matching exactly how Show-GuiDialog itself builds its own Yes/No buttons -- a helper called twice would create its own scope torn down on return, and this app's plain (non-GetNewClosure()'d) click handlers depend on their defining scope staying alive, the same lesson the GUI modularization refactor already hit once.

function Show-GuiModeSelection {
  # This is the first WPF code to run in GUI mode, before Show-MainWindow's own Add-Type call -- without loading the assembly here too, every System.Windows.* New-Object call below fails silently (non-terminating), and since Start.ps1 already hid the console window by this point, the process just exits with no visible GUI and no visible error.
  Add-Type -AssemblyName PresentationFramework

  # Uses a script-scope result variable, not a local one, for the same reason Show-GuiDialog's own $script:GuiDialogResult does: a button's Click handler runs in its own nested scope, where a plain assignment would only ever create a new local shadow copy instead of writing back to this function's variable.
  $script:GuiModeSelectionResult = $null

  $Window = New-Object System.Windows.Window
  $Window.WindowStyle = "None"
  $Window.AllowsTransparency = $true
  $Window.Background = "Transparent"
  $Window.ResizeMode = "NoResize"
  $Window.ShowInTaskbar = $true
  $Window.WindowStartupLocation = "CenterScreen"
  $Window.Width = 1360
  $Window.Height = 860

  $Overlay = New-Object System.Windows.Controls.Grid
  $Overlay.Background = "#B0000000"

  $Card = New-Object System.Windows.Controls.Border
  $Card.Background = "#1C1F26"
  $Card.BorderBrush = "#2C2F38"
  $Card.BorderThickness = New-Object System.Windows.Thickness(1)
  $Card.CornerRadius = New-Object System.Windows.CornerRadius(12)
  $Card.Padding = New-Object System.Windows.Thickness(36)
  $Card.Width = 640
  $Card.HorizontalAlignment = "Center"
  $Card.VerticalAlignment = "Center"

  $CardStack = New-Object System.Windows.Controls.StackPanel

  $TitleText = New-Object System.Windows.Controls.TextBlock
  $TitleText.Text = "IT Deployment Tool"
  $TitleText.Foreground = "#E8E9EC"
  $TitleText.FontSize = 20
  $TitleText.FontWeight = "Bold"
  $TitleText.HorizontalAlignment = "Center"
  $TitleText.Margin = New-Object System.Windows.Thickness(0, 0, 0, 6)
  $CardStack.Children.Add($TitleText) | Out-Null

  $SubtitleText = New-Object System.Windows.Controls.TextBlock
  $SubtitleText.Text = "Select deployment mode"
  $SubtitleText.Foreground = "#9A9EA8"
  $SubtitleText.FontSize = 13
  $SubtitleText.HorizontalAlignment = "Center"
  $SubtitleText.Margin = New-Object System.Windows.Thickness(0, 0, 0, 26)
  $CardStack.Children.Add($SubtitleText) | Out-Null

  $ChoiceRow = New-Object System.Windows.Controls.StackPanel
  $ChoiceRow.Orientation = "Horizontal"
  $ChoiceRow.HorizontalAlignment = "Center"

  # --- IT choice card ---
  $ItCard = New-Object System.Windows.Controls.Border
  $ItCard.Background = "#23262E"
  $ItCard.BorderBrush = "#2C2F38"
  $ItCard.BorderThickness = New-Object System.Windows.Thickness(1)
  $ItCard.CornerRadius = New-Object System.Windows.CornerRadius(10)
  $ItCard.Padding = New-Object System.Windows.Thickness(20)
  $ItCard.Width = 260
  $ItCard.Margin = New-Object System.Windows.Thickness(10, 0, 10, 0)

  $ItStack = New-Object System.Windows.Controls.StackPanel

  $ItButton = New-GuiDialogButton -Content "IT" -Background "#38BDF8" -Foreground "#08131A" -Bold
  $ItButton.HorizontalAlignment = "Stretch"
  $ItButton.HorizontalContentAlignment = "Center"
  $ItButton.FontSize = 15
  $ItButton.Margin = New-Object System.Windows.Thickness(0, 0, 0, 12)
  $ItButton.Add_Click({
    $script:GuiModeSelectionResult = "IT"
    $Window.Close()
  })
  $ItStack.Children.Add($ItButton) | Out-Null

  $ItDescription = New-Object System.Windows.Controls.TextBlock
  $ItDescription.Text = "All features and application categories."
  $ItDescription.Foreground = "#9A9EA8"
  $ItDescription.FontSize = 11.5
  $ItDescription.TextWrapping = "Wrap"
  $ItDescription.HorizontalAlignment = "Center"
  $ItDescription.TextAlignment = "Center"
  $ItStack.Children.Add($ItDescription) | Out-Null

  $ItCard.Child = $ItStack
  $ChoiceRow.Children.Add($ItCard) | Out-Null

  # --- Employee choice card ---
  $EmployeeCard = New-Object System.Windows.Controls.Border
  $EmployeeCard.Background = "#23262E"
  $EmployeeCard.BorderBrush = "#2C2F38"
  $EmployeeCard.BorderThickness = New-Object System.Windows.Thickness(1)
  $EmployeeCard.CornerRadius = New-Object System.Windows.CornerRadius(10)
  $EmployeeCard.Padding = New-Object System.Windows.Thickness(20)
  $EmployeeCard.Width = 260
  $EmployeeCard.Margin = New-Object System.Windows.Thickness(10, 0, 10, 0)

  $EmployeeStack = New-Object System.Windows.Controls.StackPanel

  $EmployeeButton = New-GuiDialogButton -Content "Employee" -Background "#38BDF8" -Foreground "#08131A" -Bold
  $EmployeeButton.HorizontalAlignment = "Stretch"
  $EmployeeButton.HorizontalContentAlignment = "Center"
  $EmployeeButton.FontSize = 15
  $EmployeeButton.Margin = New-Object System.Windows.Thickness(0, 0, 0, 12)
  $EmployeeButton.Add_Click({
    $script:GuiModeSelectionResult = "Employee"
    $Window.Close()
  })
  $EmployeeStack.Children.Add($EmployeeButton) | Out-Null

  $EmployeeDescription = New-Object System.Windows.Controls.TextBlock
  $EmployeeDescription.Text = "Applications only -- Browsers, Communication, Remote Support, Company Apps, Productivity, Printers."
  $EmployeeDescription.Foreground = "#9A9EA8"
  $EmployeeDescription.FontSize = 11.5
  $EmployeeDescription.TextWrapping = "Wrap"
  $EmployeeDescription.HorizontalAlignment = "Center"
  $EmployeeDescription.TextAlignment = "Center"
  $EmployeeStack.Children.Add($EmployeeDescription) | Out-Null

  $EmployeeCard.Child = $EmployeeStack
  $ChoiceRow.Children.Add($EmployeeCard) | Out-Null

  $CardStack.Children.Add($ChoiceRow) | Out-Null
  $Card.Child = $CardStack
  $Overlay.Children.Add($Card) | Out-Null
  $Window.Content = $Overlay

  [void]$Window.ShowDialog()

  return $script:GuiModeSelectionResult
}
