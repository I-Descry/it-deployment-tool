# ============================================================
# UNINSTALLATION ROUTER
# ============================================================

function Uninstall-ApplicationByType {
  param(
    [Parameter(Mandatory)]
    [PSCustomObject]$Application
  )

  # AppxPackageName overrides InstallType-based uninstall, matching detection precedence.
  $AppxPackageName = ([string]$Application.AppxPackageName).Trim()

  if (-not [string]::IsNullOrWhiteSpace($AppxPackageName)) {
    $RawResult = Uninstall-ApplicationWithAppx -Application $Application

    return ConvertTo-ApplicationUninstallationResult -Result $RawResult -ApplicationName $Application.Name
  }

  $InstallType = ([string]$Application.InstallType).Trim().ToUpperInvariant()

  switch ($InstallType) {
    "WINGET" {
      $RawResult = Uninstall-ApplicationWithWinget -Application $Application

      return ConvertTo-ApplicationUninstallationResult -Result $RawResult -ApplicationName $Application.Name
    }

    "EXE" {
      $RawResult = Uninstall-ApplicationWithExe -Application $Application

      return ConvertTo-ApplicationUninstallationResult -Result $RawResult -ApplicationName $Application.Name
    }

    "MSI" {
      $RawResult = Uninstall-ApplicationWithMsi -Application $Application

      return ConvertTo-ApplicationUninstallationResult -Result $RawResult -ApplicationName $Application.Name
    }

    default {
      $Message = ("Uninstallation is not yet supported for {0}: {1}" -f $Application.Name, $InstallType)

      Write-Host
      Write-Host $Message -ForegroundColor Red

      Write-DeploymentLog -Message $Message -Level "ERROR"

      return New-ApplicationUninstallationResult -Status "Failed" -ApplicationName $Application.Name -Message $Message
    }
  }
}
