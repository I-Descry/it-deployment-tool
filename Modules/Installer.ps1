# ============================================================
# APPLICATION INSTALLER
# ============================================================

function Get-WingetInstallArguments {
  param(
    [PSCustomObject]$Application
  )

  return @(
    "install"
    "--id"
    $Application.Winget
    "--exact"
    "--source"
    "winget"
    "--silent"
    "--accept-package-agreements"
    "--accept-source-agreements"
    "--disable-interactivity"
  )
}

function Test-WingetPackage {
  param(
    [PSCustomObject]$Application
  )

  $WingetArguments = @(
    "show"
    "--id"
    $Application.Winget
    "--exact"
    "--source"
    "winget"
    "--accept-source-agreements"
    "--disable-interactivity"
  )

  & winget @WingetArguments *> $null

  return ($LASTEXITCODE -eq 0)
}

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

function Install-ApplicationWithWinget {
  param(
    [PSCustomObject]$Application
  )

  Write-Host
  Write-Host "Installing $($Application.Name)..." -ForegroundColor Cyan

  $WingetArguments = Get-WingetInstallArguments -Application $Application

  & winget @WingetArguments

  $ExitCode = $LASTEXITCODE
 
  if ($ExitCode -eq 0) {
    Write-Host
    Write-Host "$($Application.Name) installed successfully." -ForegroundColor Green

    return $true
  }

  Write-Host
  Write-Host ("$($Application.Name) failed. Exit code: {0}" -f $ExitCode) -ForegroundColor Red

  return $false
}
function Install-SelectedApplications {
  $SelectedApplications = @(Get-SelectedApplications)

  if ($SelectedApplications.Count -eq 0) {
    Write-Host
    Write-Host "No applications selected." -ForegroundColor Yellow
    Pause-Application

    return
  }

  Write-Host
  Write-Host "Starting installation queue..." -ForegroundColor Cyan

  for (
    $Index = 0
    $Index -lt $SelectedApplications.Count
    $Index++
  ) {
    $Application = $SelectedApplications[$Index]
    $CurrentNumber = $Index + 1

    Write-Host
    Write-Host ("[{0}/{1}] {2}" -f $CurrentNumber, $SelectedApplications.Count, $Application.Name) -ForegroundColor Cyan
    Write-Host "Checking package..." -NoNewline

    $PackageExists = Test-WingetPackage -Application $Application

    if (-not $PackageExists) {
      Write-Host " [ NOT FOUND ]" -ForegroundColor Red
      continue
    }

    Write-Host " [ OK ]" -ForegroundColor Green

    $AlreadyInstalled = Test-ApplicationInstalled -Application $Application
    
    if ($AlreadyInstalled) {
      Write-Host ("$($Application.Name) is already installed. Skipping.") -ForegroundColor Yellow
      continue
    }

    [void](
      Install-ApplicationWithWinget -Application $Application
    )
  }

  Write-Host
  Write-Host "Installation queue completed." -ForegroundColor Cyan
  
  Pause-Application
}