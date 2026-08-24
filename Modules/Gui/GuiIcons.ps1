# ============================================================
# GUI ICONS
# ============================================================
# Shared icon-building primitives, ported from the approved mockup's SVG
# icons into WPF Canvas + Rectangle/Ellipse/Line/Path shapes (WPF cannot
# render SVG directly). Used by the sidebar nav icons (static XAML), the
# Applications screen's category headers and Recommended star, and the
# nav icon color-switching in Switch-GuiScreen.

function New-GuiIconShape {
  param(
    [Parameter(Mandatory)]
    [ValidateSet("Rectangle", "Ellipse", "Line", "Path")]
    [string]$Type,

    [string]$Color = "#9A9EA8",
    [double]$StrokeThickness = 1.3,
    [switch]$Filled,
    [string]$Cap = "Flat",
    [string]$Join = "Miter",

    [double]$X, [double]$Y, [double]$Width, [double]$Height, [double]$RadiusX = 0,
    [double]$Cx, [double]$Cy, [double]$Rx, [double]$Ry,
    [double]$X1, [double]$Y1, [double]$X2, [double]$Y2,
    [string]$Data
  )

  $Brush = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.ColorConverter]::ConvertFromString($Color))

  switch ($Type) {
    "Rectangle" {
      $Shape = New-Object System.Windows.Shapes.Rectangle
      $Shape.Width = $Width; $Shape.Height = $Height; $Shape.RadiusX = $RadiusX; $Shape.RadiusY = $RadiusX
      $Shape.Stroke = $Brush; $Shape.StrokeThickness = $StrokeThickness
      [System.Windows.Controls.Canvas]::SetLeft($Shape, $X)
      [System.Windows.Controls.Canvas]::SetTop($Shape, $Y)
    }
    "Ellipse" {
      $Shape = New-Object System.Windows.Shapes.Ellipse
      $Shape.Width = $Rx * 2; $Shape.Height = $Ry * 2
      $Shape.Stroke = $Brush; $Shape.StrokeThickness = $StrokeThickness
      [System.Windows.Controls.Canvas]::SetLeft($Shape, $Cx - $Rx)
      [System.Windows.Controls.Canvas]::SetTop($Shape, $Cy - $Ry)
    }
    "Line" {
      $Shape = New-Object System.Windows.Shapes.Line
      $Shape.X1 = $X1; $Shape.Y1 = $Y1; $Shape.X2 = $X2; $Shape.Y2 = $Y2
      $Shape.Stroke = $Brush; $Shape.StrokeThickness = $StrokeThickness
      $Shape.StrokeStartLineCap = $Cap; $Shape.StrokeEndLineCap = $Cap
    }
    "Path" {
      $Shape = New-Object System.Windows.Shapes.Path
      $Shape.Data = [System.Windows.Media.Geometry]::Parse($Data)
      if ($Filled) {
        $Shape.Fill = $Brush
      }
      else {
        $Shape.Stroke = $Brush
        $Shape.StrokeThickness = $StrokeThickness
        $Shape.StrokeStartLineCap = $Cap; $Shape.StrokeEndLineCap = $Cap; $Shape.StrokeLineJoin = $Join
      }
    }
  }

  return $Shape
}

function New-GuiCategoryIcon {
  param(
    [Parameter(Mandatory)]
    [string]$CategoryName,

    [string]$Color = "#9A9EA8"
  )

  $Canvas = New-Object System.Windows.Controls.Canvas
  $Canvas.Width = 16
  $Canvas.Height = 16

  $Shapes = switch ($CategoryName) {
    "Browsers" {
      @(
        New-GuiIconShape -Type Ellipse -Color $Color -Cx 8 -Cy 8 -Rx 6 -Ry 6
        New-GuiIconShape -Type Ellipse -Color $Color -Cx 8 -Cy 8 -Rx 2.6 -Ry 6
        New-GuiIconShape -Type Line -Color $Color -X1 2 -Y1 8 -X2 14 -Y2 8
      )
    }
    "Communication" {
      @(New-GuiIconShape -Type Path -Color $Color -Data "M2 3.5h12a1 1 0 011 1v6a1 1 0 01-1 1H6.5l-3 3v-3H2a1 1 0 01-1-1v-6a1 1 0 011-1z")
    }
    "Remote Support" {
      @(
        New-GuiIconShape -Type Rectangle -Color $Color -X 1.5 -Y 2.5 -Width 13 -Height 9 -RadiusX 1
        New-GuiIconShape -Type Line -Color $Color -X1 5.5 -Y1 14 -X2 10.5 -Y2 14
        New-GuiIconShape -Type Line -Color $Color -X1 8 -Y1 11.5 -X2 8 -Y2 14
      )
    }
    "Network Tools" {
      @(
        New-GuiIconShape -Type Ellipse -Color $Color -Cx 8 -Cy 3 -Rx 1.6 -Ry 1.6
        New-GuiIconShape -Type Ellipse -Color $Color -Cx 3 -Cy 12.5 -Rx 1.6 -Ry 1.6
        New-GuiIconShape -Type Ellipse -Color $Color -Cx 13 -Cy 12.5 -Rx 1.6 -Ry 1.6
        New-GuiIconShape -Type Line -Color $Color -X1 8 -Y1 4.6 -X2 4 -Y2 11.1
        New-GuiIconShape -Type Line -Color $Color -X1 8 -Y1 4.6 -X2 12 -Y2 11.1
      )
    }
    "Development Tools" {
      @(New-GuiIconShape -Type Path -Color $Color -Cap Round -Join Round -Data "M5.5 3.5L2 8l3.5 4.5M10.5 3.5L14 8l-3.5 4.5")
    }
    "Company Applications" {
      @(
        New-GuiIconShape -Type Rectangle -Color $Color -X 1.5 -Y 5 -Width 13 -Height 8.5 -RadiusX 1
        New-GuiIconShape -Type Path -Color $Color -Data "M5.5 5V3.5a1 1 0 011-1h3a1 1 0 011 1V5"
        New-GuiIconShape -Type Line -Color $Color -X1 1.5 -Y1 9 -X2 14.5 -Y2 9
      )
    }
    "Security" {
      @(New-GuiIconShape -Type Path -Color $Color -Data "M8 1.5l5.5 2v4c0 4-2.4 6.3-5.5 7-3.1-.7-5.5-3-5.5-7v-4L8 1.5z")
    }
    "Utilities" {
      @(New-GuiIconShape -Type Path -Color $Color -Join Round -Data "M11 2a3 3 0 00-3.9 3.9L2 11l2 2 5.1-5.1A3 3 0 0013 4l-2 2-1.5-.5L9 4l2-2z")
    }
    default {
      # Generic folder outline for any category not in the mockup's original set.
      @(New-GuiIconShape -Type Path -Color $Color -Data "M2 4.5a1 1 0 011-1h3.5l1.5 2h5a1 1 0 011 1v6a1 1 0 01-1 1H3a1 1 0 01-1-1v-8z")
    }
  }

  foreach ($Shape in $Shapes) {
    $Canvas.Children.Add($Shape) | Out-Null
  }

  return $Canvas
}

function New-GuiRecommendedIcon {
  $Canvas = New-Object System.Windows.Controls.Canvas
  $Canvas.Width = 11
  $Canvas.Height = 11
  $Canvas.RenderTransform = New-Object System.Windows.Media.ScaleTransform((11 / 24), (11 / 24))

  $Star = New-GuiIconShape -Type Path -Color "#FBBF24" -Filled -Data "M12 2l2.9 6.9L22 9.8l-5.5 4.8L18 22l-6-3.6L6 22l1.5-7.4L2 9.8l7.1-.9L12 2z"
  $Canvas.Children.Add($Star) | Out-Null

  return $Canvas
}

function New-GuiStatusIcon {
  param(
    [Parameter(Mandatory)]
    [bool]$Passed
  )

  $Canvas = New-Object System.Windows.Controls.Canvas
  $Canvas.Width = 10
  $Canvas.Height = 10

  if ($Passed) {
    $Mark = New-GuiIconShape -Type Path -Color "#0B1116" -StrokeThickness 1.6 -Cap Round -Join Round -Data "M1.5 5L4 7.5L8.5 2"
    $BadgeColor = "#34D399"
  }
  else {
    $Mark = New-GuiIconShape -Type Path -Color "#0B1116" -StrokeThickness 1.6 -Cap Round -Join Round -Data "M2 2L8 8M8 2L2 8"
    $BadgeColor = "#F2555A"
  }

  $Badge = New-Object System.Windows.Shapes.Ellipse
  $Badge.Width = 10
  $Badge.Height = 10
  $Badge.Fill = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.ColorConverter]::ConvertFromString($BadgeColor))
  $Canvas.Children.Add($Badge) | Out-Null
  $Canvas.Children.Add($Mark) | Out-Null

  return $Canvas
}

function New-GuiSectionHeaderIcon {
  param(
    [Parameter(Mandatory)]
    [ValidateSet("DeviceReadiness", "InstallerPackages", "DeploymentLogs")]
    [string]$IconName,

    [string]$Color = "#38BDF8"
  )

  $Canvas = New-Object System.Windows.Controls.Canvas
  $Canvas.Width = 16
  $Canvas.Height = 16

  $Shapes = switch ($IconName) {
    "DeviceReadiness" {
      @(
        New-GuiIconShape -Type Path -Color $Color -StrokeThickness 1.4 -Data "M8 1.5l5.5 2v4c0 4-2.4 6.3-5.5 7-3.1-.7-5.5-3-5.5-7v-4L8 1.5z"
        New-GuiIconShape -Type Path -Color $Color -StrokeThickness 1.4 -Cap Round -Join Round -Data "M5.5 8l1.8 1.8L10.5 6"
      )
    }
    "InstallerPackages" {
      @(
        New-GuiIconShape -Type Path -Color $Color -StrokeThickness 1.3 -Join Round -Data "M2 5.5l6-3.5 6 3.5-6 3.5-6-3.5z"
        New-GuiIconShape -Type Path -Color $Color -StrokeThickness 1.3 -Data "M2 5.5v5l6 3.5 6-3.5v-5"
        New-GuiIconShape -Type Line -Color $Color -StrokeThickness 1.3 -X1 8 -Y1 9 -X2 8 -Y2 14
      )
    }
    "DeploymentLogs" {
      @(
        New-GuiIconShape -Type Rectangle -Color $Color -StrokeThickness 1.4 -X 3.5 -Y 1.5 -Width 9 -Height 13 -RadiusX 1.2
        New-GuiIconShape -Type Line -Color $Color -StrokeThickness 1.2 -X1 6 -Y1 5 -X2 10 -Y2 5
        New-GuiIconShape -Type Line -Color $Color -StrokeThickness 1.2 -X1 6 -Y1 7.7 -X2 10 -Y2 7.7
        New-GuiIconShape -Type Line -Color $Color -StrokeThickness 1.2 -X1 6 -Y1 10.4 -X2 8.7 -Y2 10.4
      )
    }
  }

  foreach ($Shape in $Shapes) {
    $Canvas.Children.Add($Shape) | Out-Null
  }

  return $Canvas
}

function Set-GuiIconColor {
  param(
    [Parameter(Mandatory)]
    [System.Windows.Controls.Canvas]$IconCanvas,

    [Parameter(Mandatory)]
    [string]$Color
  )

  $Brush = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.ColorConverter]::ConvertFromString($Color))

  foreach ($Child in $IconCanvas.Children) {
    if ($null -ne $Child.Stroke) {
      $Child.Stroke = $Brush
    }
  }
}
