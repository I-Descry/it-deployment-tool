# ============================================================
# GUI DIALOG
# ============================================================
# A reusable, dark-themed modal that replaces the native MessageBox.Show,
# which renders as a plain white Windows dialog out of place against this
# app's dark UI. Built as its own WPF Window rather than an in-app overlay
# Border (like CompletionModalOverlay) specifically so ShowDialog() can
# still block and return a result synchronously, exactly like
# MessageBox.Show did -- every existing call site only needs to swap the
# function name and how it reads the result back, not be restructured into
# a callback. Visually it reuses CompletionModalOverlay's own language: a
# dimmed backdrop over the app and a centered rounded card.

function New-GuiDialogIconCanvas {
  param(
    [Parameter(Mandatory)]
    [ValidateSet("Info", "Success", "Warning")]
    [string]$Icon
  )

  $Canvas = New-Object System.Windows.Controls.Canvas
  $Canvas.Width = 22
  $Canvas.Height = 22

  switch ($Icon) {
    "Success" {
      # Same circle+check glyph and color as CompletionModalIconSuccess in MainWindow.xaml.
      $Color = "#34D399"

      $Circle = New-Object System.Windows.Shapes.Ellipse
      $Circle.Width = 22
      $Circle.Height = 22
      $Circle.Stroke = $Color
      $Circle.StrokeThickness = 1.6
      $Canvas.Children.Add($Circle) | Out-Null

      $Check = New-Object System.Windows.Shapes.Path
      $Check.Stroke = $Color
      $Check.StrokeThickness = 1.8
      $Check.StrokeStartLineCap = "Round"
      $Check.StrokeEndLineCap = "Round"
      $Check.StrokeLineJoin = "Round"
      $Check.Data = [System.Windows.Media.Geometry]::Parse("M6.5 11l3 3L16 7")
      $Canvas.Children.Add($Check) | Out-Null
    }
    "Warning" {
      # Same triangle+exclamation glyph and color as CompletionModalIconWarning. This app's real semantic palette only has two non-neutral colors (green = good, red = needs attention/failed, e.g. the Deployment Validation "Attention" pill), not a separate amber warning tone, so this same red icon covers both a confirm-before-you-proceed prompt and an outright error/failure message.
      $Color = "#F2555A"

      $Triangle = New-Object System.Windows.Shapes.Path
      $Triangle.Stroke = $Color
      $Triangle.StrokeThickness = 1.6
      $Triangle.StrokeLineJoin = "Round"
      $Triangle.Data = [System.Windows.Media.Geometry]::Parse("M11 2.5l9.5 16.5H1.5L11 2.5z")
      $Canvas.Children.Add($Triangle) | Out-Null

      $Stem = New-Object System.Windows.Shapes.Line
      $Stem.X1 = 11; $Stem.Y1 = 9; $Stem.X2 = 11; $Stem.Y2 = 13.5
      $Stem.Stroke = $Color
      $Stem.StrokeThickness = 1.6
      $Stem.StrokeStartLineCap = "Round"
      $Canvas.Children.Add($Stem) | Out-Null

      $Dot = New-Object System.Windows.Shapes.Line
      $Dot.X1 = 11; $Dot.Y1 = 15.9; $Dot.X2 = 11; $Dot.Y2 = 16.1
      $Dot.Stroke = $Color
      $Dot.StrokeThickness = 2
      $Dot.StrokeStartLineCap = "Round"
      $Canvas.Children.Add($Dot) | Out-Null
    }
    default {
      # Same circle-i glyph already used for every card-header icon on the Windows Setup / Device Details screens (Identity, System, etc.).
      $Color = "#38BDF8"

      $Circle = New-Object System.Windows.Shapes.Ellipse
      $Circle.Width = 20
      $Circle.Height = 20
      [System.Windows.Controls.Canvas]::SetLeft($Circle, 1)
      [System.Windows.Controls.Canvas]::SetTop($Circle, 1)
      $Circle.Stroke = $Color
      $Circle.StrokeThickness = 1.6
      $Canvas.Children.Add($Circle) | Out-Null

      $Stem = New-Object System.Windows.Shapes.Line
      $Stem.X1 = 11; $Stem.Y1 = 9.7; $Stem.X2 = 11; $Stem.Y2 = 15.8
      $Stem.Stroke = $Color
      $Stem.StrokeThickness = 1.8
      $Stem.StrokeStartLineCap = "Round"
      $Stem.StrokeEndLineCap = "Round"
      $Canvas.Children.Add($Stem) | Out-Null

      $Dot = New-Object System.Windows.Shapes.Line
      $Dot.X1 = 11; $Dot.Y1 = 6.2; $Dot.X2 = 11; $Dot.Y2 = 6.4
      $Dot.Stroke = $Color
      $Dot.StrokeThickness = 2.4
      $Dot.StrokeStartLineCap = "Round"
      $Dot.StrokeEndLineCap = "Round"
      $Canvas.Children.Add($Dot) | Out-Null
    }
  }

  return $Canvas
}

function Show-GuiDialog {
  param(
    [Parameter(Mandatory)]
    [string]$Message,

    [string]$Title = "IT Deployment Tool",

    [ValidateSet("OK", "YesNo")]
    [string]$Buttons = "OK",

    [ValidateSet("Info", "Success", "Warning")]
    [string]$Icon = "Info",

    [System.Windows.Window]$Owner
  )

  if ($null -eq $Owner) {
    $Owner = $script:GuiMainWindow
  }

  # A single script-scope result variable, not a variable local to this function, because a button's Click handler runs in its own nested scope where a plain assignment (`$Result = "Yes"`) would only ever create a new local shadow copy instead of writing back to this function's variable -- the same read-vs-write asymmetry documented elsewhere in this app's click handlers, just hitting the write side here instead of the read side. Routing the write through $script: is how the rest of this codebase already works around exactly that.
  $script:GuiDialogResult = if ($Buttons -eq "YesNo") { "No" } else { "OK" }

  $Dialog = New-Object System.Windows.Window
  $Dialog.WindowStyle = "None"
  $Dialog.AllowsTransparency = $true
  $Dialog.Background = "Transparent"
  $Dialog.ResizeMode = "NoResize"
  $Dialog.ShowInTaskbar = $false

  if ($null -ne $Owner) {
    $Dialog.Owner = $Owner
    $Dialog.WindowStartupLocation = "Manual"
    $Dialog.Left = $Owner.Left
    $Dialog.Top = $Owner.Top
    $Dialog.Width = $Owner.ActualWidth
    $Dialog.Height = $Owner.ActualHeight
  }
  else {
    $Dialog.WindowStartupLocation = "CenterScreen"
    $Dialog.Width = 1360
    $Dialog.Height = 860
  }

  $Overlay = New-Object System.Windows.Controls.Grid
  $Overlay.Background = "#B0000000"

  $Card = New-Object System.Windows.Controls.Border
  $Card.Background = "#1C1F26"
  $Card.BorderBrush = "#2C2F38"
  $Card.BorderThickness = New-Object System.Windows.Thickness(1)
  $Card.CornerRadius = New-Object System.Windows.CornerRadius(12)
  $Card.Padding = New-Object System.Windows.Thickness(28)
  $Card.Width = 440
  $Card.HorizontalAlignment = "Center"
  $Card.VerticalAlignment = "Center"

  $CardStack = New-Object System.Windows.Controls.StackPanel

  $HeaderStack = New-Object System.Windows.Controls.StackPanel
  $HeaderStack.Orientation = "Horizontal"
  $HeaderStack.Margin = New-Object System.Windows.Thickness(0, 0, 0, 14)

  $IconCanvas = New-GuiDialogIconCanvas -Icon $Icon
  $IconCanvas.Margin = New-Object System.Windows.Thickness(0, 0, 12, 0)
  $HeaderStack.Children.Add($IconCanvas) | Out-Null

  $TitleText = New-Object System.Windows.Controls.TextBlock
  $TitleText.Text = $Title
  $TitleText.Foreground = "#E8E9EC"
  $TitleText.FontSize = 16
  $TitleText.FontWeight = "Bold"
  $TitleText.VerticalAlignment = "Center"
  $HeaderStack.Children.Add($TitleText) | Out-Null

  $CardStack.Children.Add($HeaderStack) | Out-Null

  $MessageText = New-Object System.Windows.Controls.TextBlock
  $MessageText.Text = $Message
  $MessageText.Foreground = "#9A9EA8"
  $MessageText.FontSize = 13
  $MessageText.TextWrapping = "Wrap"
  $MessageText.Margin = New-Object System.Windows.Thickness(0, 0, 0, 22)
  $CardStack.Children.Add($MessageText) | Out-Null

  $ButtonRow = New-Object System.Windows.Controls.StackPanel
  $ButtonRow.Orientation = "Horizontal"
  $ButtonRow.HorizontalAlignment = "Right"

  if ($Buttons -eq "YesNo") {
    $NoButton = New-Object System.Windows.Controls.Button
    $NoButton.Content = "No"
    $NoButton.Padding = New-Object System.Windows.Thickness(20, 8, 20, 8)
    $NoButton.Margin = New-Object System.Windows.Thickness(0, 0, 10, 0)
    $NoButton.Background = "#23262E"
    $NoButton.Foreground = "#E8E9EC"
    $NoButton.BorderBrush = "#2C2F38"
    $NoButton.BorderThickness = New-Object System.Windows.Thickness(1)
    $NoButton.FontSize = 13
    $NoButton.IsCancel = $true
    $NoButton.Add_Click({
      $script:GuiDialogResult = "No"
      $Dialog.Close()
    })
    $ButtonRow.Children.Add($NoButton) | Out-Null

    $YesButton = New-Object System.Windows.Controls.Button
    $YesButton.Content = "Yes"
    $YesButton.Padding = New-Object System.Windows.Thickness(20, 8, 20, 8)
    $YesButton.Background = "#38BDF8"
    $YesButton.Foreground = "#08131A"
    $YesButton.BorderThickness = New-Object System.Windows.Thickness(0)
    $YesButton.FontSize = 13
    $YesButton.FontWeight = "Bold"
    $YesButton.IsDefault = $true
    $YesButton.Add_Click({
      $script:GuiDialogResult = "Yes"
      $Dialog.Close()
    })
    $ButtonRow.Children.Add($YesButton) | Out-Null
  }
  else {
    $OkButton = New-Object System.Windows.Controls.Button
    $OkButton.Content = "OK"
    $OkButton.Padding = New-Object System.Windows.Thickness(24, 8, 24, 8)
    $OkButton.Background = "#38BDF8"
    $OkButton.Foreground = "#08131A"
    $OkButton.BorderThickness = New-Object System.Windows.Thickness(0)
    $OkButton.FontSize = 13
    $OkButton.FontWeight = "Bold"
    $OkButton.IsDefault = $true
    $OkButton.IsCancel = $true
    $OkButton.Add_Click({
      $script:GuiDialogResult = "OK"
      $Dialog.Close()
    })
    $ButtonRow.Children.Add($OkButton) | Out-Null
  }

  $CardStack.Children.Add($ButtonRow) | Out-Null
  $Card.Child = $CardStack
  $Overlay.Children.Add($Card) | Out-Null
  $Dialog.Content = $Overlay

  [void]$Dialog.ShowDialog()

  return $script:GuiDialogResult
}
