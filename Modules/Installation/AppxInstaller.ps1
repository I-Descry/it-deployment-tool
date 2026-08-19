# ============================================================
# APPX/MSIX UNINSTALLER
# ============================================================

function Uninstall-ApplicationWithAppx {
  param(
    [Parameter(Mandatory)]
    [PSCustomObject]$Application
  )

  $PackageName = ([string]$Application.AppxPackageName).Trim()

  Write-Host
  Write-Host ("Uninstalling {0}..." -f $Application.Name) -ForegroundColor Cyan
  
  Write-DeploymentLog -Message ("Appx uninstallation started: {0} ({1})" -f $Application.Name, $PackageName)

  try {
    $Package = Get-AppxPackage -Name $PackageName -ErrorAction Stop | Select-Object -First 1

    if ($null -eq $Package) {
      $Message = ("{0} AppX package was not found." -f $Application.Name)

      Write-Host
      Write-Host $Message -ForegroundColor Yellow

      Write-DeploymentLog -Message $Message -Level "WARNING"

      return $false
    }

    Remove-AppxPackage -Package $Package.PackageFullName -ErrorAction Stop

    Write-Host
    Write-Host ("{0} uninstalled successfully." -f $Application.Name) -ForegroundColor Green

    Write-DeploymentLog -Message ("{0} uninstalled successfully." -f $Application.Name) -Level "SUCCESS"

    return $true
  }

  catch {
    Write-Host
    Write-Host ("{0} uninstallation failed: {1}" -f $Application.Name, $_.Exception.Message) -ForegroundColor Red

    Write-DeploymentLog -Message ("{0} AppX uninstallation failed: {1}" -f $Application.Name, $_.Exception.Message) -Level "ERROR"
  
    return $false
  }
}