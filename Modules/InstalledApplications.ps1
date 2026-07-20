# ============================================================
# INSTALLED APPLICATION DETECTION
# ============================================================

function Test-ApplicationInstalled {
  param(
    [PSCustomObject]$Application
  )

  $DetectionName = ([string]$Application.DetectionName).Trim()

  if ([string]::IsNullOrWhiteSpace($DetectionName)) {
    $DetectionName = ([string]$Application.Name).Trim()
  }

  if ([string]::IsNullOrWhiteSpace($DetectionName)) {
    return $false
  }

  $RegistryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
  )

  $InstalledApplication = Get-ItemProperty -Path $RegistryPaths -ErrorAction SilentlyContinue |
  Where-Object {
    $DisplayName = ([string]$_.DisplayName).Trim()

    if ([string]::IsNullOrWhiteSpace($DisplayName)) {
      return $false
    }

    return $DisplayName.StartsWith(
      $DetectionName,
      [System.StringComparison]::OrdinalIgnoreCase
    )
  } |
  Select-Object -First 1

  return ($null -ne $InstalledApplication)
}