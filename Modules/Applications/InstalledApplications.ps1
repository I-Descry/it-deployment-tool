# ============================================================
# INSTALLED APPLICATION DETECTION
# ============================================================

$script:InstalledApplicationRegistryCache = @{
  Machine = @()
  user    = @()
}

function Update-InstalledApplicationRegistryCache {
  $MachineRegistryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
  )

  $UserRegistryPaths = @(
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
  )

  $script:InstalledApplicationRegistryCache.Machine = @(Get-ItemProperty -Path $MachineRegistryPaths -ErrorAction SilentlyContinue | ForEach-Object {
    ([string]$_.DisplayName).Trim()
  } | Where-Object {
    -not [string]::IsNullOrWhiteSpace($_)
  })

  $script:InstalledApplicationRegistryCache.User = @(Get-ItemProperty -Path $UserRegistryPaths -ErrorAction SilentlyContinue | ForEach-Object {
    ([string]$_.DisplayName).Trim()
  } | Where-Object {
    -not [string]::IsNullOrWhiteSpace($_)
  })
}

function Test-CacheRegistryApplicationInstalled {
  param(
    [Parameter(Mandatory)]
    [string]$DetectionName,

    [string]$Scope
  )

  $InstalledNames = switch ($Scope.Trim().ToLowerInvariant()) {
    "machine" {
      @($script:InstalledApplicationRegistryCache.Machine)
    }

    "user" {
      @($script:InstalledApplicationRegistryCache.User)
    }

    default {
      @(
        $script:InstalledApplicationRegistryCache.Machine
        $script:InstalledApplicationRegistryCache.User
      )
    }
  }

  foreach ($DisplayName in $InstalledNames) {
    if ($DisplayName.StartsWith($DetectionName,[System.StringComparison]::OrdinalIgnoreCase)) {
      return $true
    }
  }

  return $false
}

function Test-WingetApplicationInstalled {
  param([PSCustomObject]$Application)

  $PackageId = ([string]$Application.Winget).Trim()

  if ([string]::IsNullOrWhiteSpace($PackageId)) {
    return $false
  }

  $WingetCommand = Get-Command -Name "winget" -ErrorAction SilentlyContinue

  if ($null -eq $WingetCommand) {
    return $false
  }

  $WingetArguments = @(
    "list"
    "--id"
    $PackageId
    "--exact"
    "--source"
    "winget"
    "--accept-source-agreements"
    "--disable-interactivity"
  )

  $ConfiguredScope = ([string]$Application.WingetScope).Trim()

  if (-not [string]::IsNullOrWhiteSpace($ConfiguredScope)) {
    $NormalizedScope = $ConfiguredScope.ToLowerInvariant()

    if ($NormalizedScope -in @("user", "machine")) {
      $WingetArguments += @(
        "--scope"
        $NormalizedScope
      )
    }
  }

  & winget @WingetArguments *> $null

  return ($LASTEXITCODE -eq 0)
}

function Test-AppxPackageInstalled {
  param(
    [Parameter(Mandatory)]
    [string]$PackageName
  )

  $GetAppxPackageCommand = Get-Command -Name "Get-AppxPackage" -ErrorAction SilentlyContinue

  if ($null -eq $GetAppxPackageCommand) {
    return $false
  }

  try {
    $Package = Get-AppxPackage -Name $PackageName -ErrorAction Stop | Select-Object -First 1

    return ($null -ne $Package)
  }

  catch {
    return $false
  }
}

function Test-ApplicationInstalled {
  param([PSCustomObject]$Application)

  $InstallType = ([string]$Application.InstallType).Trim().ToUpperInvariant()

  # An explicit DetectionPath overrides all other detection methods.
  $DetectionPath = ([string]$Application.DetectionPath).Trim()

  if (-not [string]::IsNullOrWhiteSpace($DetectionPath)) {
    return (Test-Path -LiteralPath $DetectionPath)
  }

  # An explicit AppxPackageName overrides registry detection for AppX/MSIX-packaged applications, which do not create classic Uninstall registry entries.
  $AppxPackageName = ([string]$Application.AppxPackageName).Trim()

  if (-not [string]::IsNullOrWhiteSpace($AppxPackageName)) {
    return (Test-AppxPackageInstalled -PackageName $AppxPackageName)
  }

  # CrowdStrike is detected through its Windows service.
  if ($InstallType -eq "CROWDSTRIKE") {
    $CrowdStrikeDetectionCommand = Get-Command -Name "Test-CrowdStrikeSensorInstalled" -ErrorAction SilentlyContinue

    if ($null -eq $CrowdStrikeDetectionCommand) {
      return $false
    }

    return [bool](Test-CrowdStrikeSensorInstalled)
  }

  # Office 2024 uses its dedicated detection function.
  if ($InstallType -eq "OFFICEISO") {
    $OfficeDetectionCommand = Get-Command -Name "Test-Office2024Installed" -ErrorAction SilentlyContinue

    if ($null -eq $OfficeDetectionCommand) {
      return $false
    }

    return [bool](Test-Office2024Installed)
  }

  # Office 2021 uses its dedicated detection function.
  if ($InstallType -eq "OFFICE2021IMG") {
    $Office2021DetectionCommand = Get-Command -Name "Test-Office2021ProPlusRetailInstalled" -ErrorAction SilentlyContinue

    if ($null -eq $Office2021DetectionCommand) {
      return $false
    }

    return [bool](Test-Office2021ProPlusRetailInstalled)
  }

  # Microsoft Teams is detected through its provisioned MSIX package.
  if ($InstallType -eq "TEAMS") {
    $TeamsDetectionCommand = Get-Command -Name "Test-MicrosoftTeamsInstalled" -ErrorAction SilentlyContinue

    if ($null -eq $TeamsDetectionCommand) {
      return $false
    }

    return [bool](Test-MicrosoftTeamsInstalled)
  }

  # WinGet applications are checked by their exact package ID first.
  if ($InstallType -eq "WINGET") {
    $DetectionMethod = ([string]$Application.DetectionMethod).Trim().ToUpperInvariant()

    if ($DetectionMethod -eq "WINGET") {
      return [bool](Test-WingetApplicationInstalled -Application $Application)
    }
  }

  # Registry detection remains the fallback.
  $DetectionName = ([string]$Application.DetectionName).Trim()

  if ([string]::IsNullOrWhiteSpace($DetectionName)) {
    $DetectionName = ([string]$Application.Name).Trim()
  }

  if ([string]::IsNullOrWhiteSpace($DetectionName)) {
    return $false
  }

  $ConfiguredScope = ([string]$Application.WingetScope).Trim()

  return Test-CacheRegistryApplicationInstalled -DetectionName $DetectionName -Scope $ConfiguredScope

  switch ($ConfiguredScope) {
    "machine" {
      $RegistryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
      )
    }

    "user" {
      $RegistryPaths = @(
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
      )
    }

    default {
      $RegistryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
      )
    }
  }

  $InstalledApplication = Get-ItemProperty -Path $RegistryPaths -ErrorAction SilentlyContinue | Where-Object {
    $DisplayName = ([string]$_.DisplayName).Trim()
    (-not [string]::IsNullOrWhiteSpace($DisplayName)) -and ($DisplayName.StartsWith($DetectionName, [System.StringComparison]::OrdinalIgnoreCase))
  } | Select-Object -First 1

  return ($null -ne $InstalledApplication)
}

function Update-ApplicationInstallationStatus {
  if ($null -eq $script:Applications) {
    throw "The application catalog has not been initialized."
  }

  Update-InstalledApplicationRegistryCache

  foreach ($Application in $script:Applications) {
    $IsInstalled = [bool](Test-ApplicationInstalled -Application $Application)

    $Application | Add-Member -MemberType NoteProperty -Name "Installed" -Value $IsInstalled -Force
  }
}