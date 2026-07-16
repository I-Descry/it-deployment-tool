function Start-Application {
  Show-Banner

  # Load system information
  Get-SystemInformation

  # Run system checks
  Test-Administrator
  Test-Internet
  Test-Winget

  # Load application database without displaying the returned objects
  [void](Initialize-Applications)

  # Display system information
  Show-SystemInformation

  # Start the application
  Start-MainMenu
}