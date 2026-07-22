function Start-Application {
  Show-Banner

  # Load system information
  Get-SystemInformation

  # Initialize Deployment Session Log
  Initialize-DeploymentLog -Version $AppVersion

  # Run system checks
  Test-Administrator
  Test-Internet
  Test-Winget

  # Load application database without displaying the returned objects
  [void](Initialize-Applications)

  # Run the Scan during setup
  Write-Host
  Write-Host "Checking installed applications..." -ForegroundColor DarkGray

  $ScanTimer = [System.Diagnostics.Stopwatch]::StartNew()

  Update-ApplicationInstallationStatus

  $ScanTimer.Stop()

  Write-Host ("Installed application status loaded in {0:N2} second(s)." -f $ScanTimer.Elapsed.TotalSeconds) -ForegroundColor Green

  # Display system information
  Show-SystemInformation

  # Start the application
  Start-MainMenu

  # Initialize Completion Log
  Complete-DeploymentLog
}