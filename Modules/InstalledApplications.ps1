# ============================================================
# INSTALLED APPLICATION DETECTION
# ============================================================

function Test-ApplicationInstalled {
  param(
    [PSCustomObject]$Application
  )

  $RegistryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
  )

  foreach ($RegistryPath in $RegistryPaths) {
    $InstalledApplication = Get-ItemProperty -Path $RegistryPath -ErrorAction SilentlyContinue |
    Where-Object {
      $_.DisplayName -and
      $_.DisplayName.Trim() -like "$($Application.Name)*"
    } |
    Select-Object -First 1

    if ($null -ne $InstalledApplication) {
      return $true
    }
  }

  return $false
}