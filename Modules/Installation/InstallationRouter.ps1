# ============================================================
# INSTALLATION ROUTER
# ============================================================

function Test-ApplicationInstallerAvailable {
  param(
    [PSCustomObject]$Application
  )

  $InstallType = [string]$Application.InstallType

  if ([string]::IsNullOrWhiteSpace($InstallType)) {
    return $false
  }

  switch ($InstallType.Trim().ToUpper()) {
    "WINGET" {
      return Test-WingetPackage -Application $Application
    }

    "EXE" {
      return Test-OfflineInstallerFile -Application $Application
    }

    "MSI" {
      return Test-OfflineInstallerFile -Application $Application
    }

    "CROWDSTRIKE" {
      $PackageTest = Test-CrowdStrikeDeploymentPackage

      return [bool]$PackageTest.Valid
    }

    "OFFICEISO" {
      try {
        $OfficeIsoPath = Get-OfficeIsoPath

        return (Test-Path -LiteralPath $OfficeIsoPath -PathType Leaf)
      }
      catch {
        return $false
      }
    }

    "OFFICE2021IMG" {
      $PackageTest = Test-Office2021DeploymentPackage

      return [bool]$PackageTest.Valid
    }

    "TEAMS" {
      $TeamsPackageCommand = Get-Command -Name "Test-MicrosoftTeamsDeploymentPackage" -ErrorAction SilentlyContinue

      if ($null -eq $TeamsPackageCommand) {
        return $false
      }

      $PackageTest = Test-MicrosoftTeamsDeploymentPackage

      return [bool]$PackageTest.Valid
    }

    default {
      return $false
    }
  }
}

function Install-ApplicationByType {
  param(
    [Parameter(Mandatory)]
    [PSCustomObject]$Application
  )

  $InstallType = ([string]$Application.InstallType).Trim().ToUpperInvariant()

  switch ($InstallType) {
    "WINGET" {
      $RawResult = Install-ApplicationWithWinget -Application $Application

      return ConvertTo-ApplicationInstallationResult -Result $RawResult -ApplicationName $Application.Name
    }

    "EXE" {
      $RawResult = Install-ApplicationWithExe -Application $Application

      return ConvertTo-ApplicationInstallationResult -Result $RawResult -ApplicationName $Application.Name
    }

    "CROWDSTRIKE" {
      $RawResult = Start-CrowdStrikeInteractiveSetup

      return ConvertTo-ApplicationInstallationResult -Result $RawResult -ApplicationName $Application.Name
    }

    "OFFICEISO" {
      $RawResult = Start-Office2024Installation

      return ConvertTo-ApplicationInstallationResult -Result $RawResult -ApplicationName $Application.Name
    }

    "OFFICE2021IMG" {
      $RawResult = Start-Office2021LOPInstallation

      return ConvertTo-ApplicationInstallationResult -Result $RawResult -ApplicationName $Application.Name
    }

    "MSI" {
      $Message = ("{0} uses MSI, but MSI installation is not enabled yet." -f $Application.Name)

      Write-Host
      Write-Host $Message -ForegroundColor Yellow

      Write-DeploymentLog -Message $Message -Level "WARNING"

      return New-ApplicationInstallationResult -Status "Failed" -ApplicationName $Application.Name -Message $Message
    }

    default {
      $Message = ("Unsupported installation type for {0}: {1}" -f $Application.Name, $InstallType)

      Write-Host
      Write-Host $Message -ForegroundColor Red

      Write-DeploymentLog -Message $Message -Level "ERROR"

      return New-ApplicationInstallationResult -Status "Failed" -ApplicationName $Application.Name -Message $Message
    }
  }
}