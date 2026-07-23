# ============================================================
# INSTALLED APPLICATION DETECTION
# ============================================================

function Test-ApplicationInstalled {
  param(
    [PSCustomObject]$Application
  )

  $InstallType = ([string]$Application.InstallType).Trim().ToUpper()

  # CrowdStrike is detected through its Windows service.
  if ($InstallType -eq "CROWDSTRIKE") {
    $CrowdStrikeDetectionCommand = Get-Command -Name "Test-CrowdStrikeSensorInstalled" -ErrorAction SilentlyContinue

    if ($null -eq $CrowdStrikeDetectionCommand) {
      return $false
    }

    return [bool](
      Test-CrowdStrikeSensorInstalled
    )
  }

  # Other applications continue using registry detection.
  $DetectionName = ([string]$Application.DetectionName).Trim()

  if ([string]::IsNullOrWhiteSpace($Detectionname)) {
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

  $InstalledApplication = Get-ItemProperty -Path $RegistryPaths -ErrorAction SilentlyContinue | Where-Object {
    $DisplayName = ([string]$_.DisplayName).Trim()

    if ([string]::IsNullOrWhiteSpace($DisplayName)) {
      return $false
    }

    return $DisplayName.StartsWith(
      $DetectionName,
      [System.StringComparison]::OrdinalIgnoreCase
    )
  } | Select-Object -first 1

  return ($null -ne $InstalledApplication)
}

function Update-ApplicationInstallationStatus {
  if ($null -eq $script:Applications) {
    throw "The application catalog has not been initialized."
  }

  foreach ($Application in $script:Applications) {
    $IsInstalled = [bool](
      Test-ApplicationInstalled -Application $Application
    )

    $Application | Add-Member -MemberType NoteProperty -Name "Installed" -Value $IsInstalled -Force
  }
}