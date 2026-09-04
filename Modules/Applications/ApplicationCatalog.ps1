# ============================================================
# APPLICATION CATALOG
# ============================================================

# Stores the application database while the tool is running
$script:Applications = @()

# Connects menu numbers to application objects
$script:ApplicationMap = @{}

# Set once at startup (console: Read-DeploymentMode in Core\UI.ps1; GUI: Show-GuiModeSelection in Gui\GuiModeSelection.ps1). Defaults to "IT" so anything that never sets it (e.g. -ValidateOnly, which never reaches either) behaves exactly as before this feature existed.
$script:DeploymentMode = "IT"

# The exact category list the user specified for Employee mode -- every other real category in Config\Applications.json (Network Tools, Development Tools, Security, Utilities, AI Tools) stays hidden.
$script:EmployeeVisibleCategories = @("Browsers", "Communication", "Remote Support", "Company Applications", "Productivity", "Printers")

function Get-VisibleApplications {
  # The one place display/selection logic should read the catalog from instead of $script:Applications directly, so both stay correctly scoped to the current mode. Deliberately NOT used by Get-SelectedApplications or Get-RequiredApplications -- the required-application check must keep evaluating the full, real catalog regardless of mode.
  if ($script:DeploymentMode -eq "Employee") {
    return @($script:Applications | Where-Object { $_.Category -in $script:EmployeeVisibleCategories })
  }

  return $script:Applications
}

function Initialize-Applications {

  $ApplicationPath = Join-Path $script:ITDeploymentToolRoot "Config\Applications.json"

  $script:Applications = Get-Content $ApplicationPath -Raw | ConvertFrom-Json

  foreach ($Application in $script:Applications) {
    $Application | Add-Member -MemberType NoteProperty -Name "Selected" -Value $false -Force

    if ($null -eq $Application.PSObject.Properties["RequiredForIssuance"]) {
      $Application | Add-Member -MemberType NoteProperty -Name "RequiredForIssuance" -Value $false
    }
  }

  return $script:Applications
}

function Get-ApplicationByNumber {

  param(
    [int]$Number
  )

  if ($script:ApplicationMap.ContainsKey($Number)) {
    return $script:ApplicationMap[$Number]
  }

  return $null
}

function Get-SelectedApplications {

  return $script:Applications | Where-Object { $_.Selected }
}

function Get-RequiredApplications {
  if ($null -eq $script:Applications) {
    return @()
  }

  return @($script:Applications | Where-Object {
    $_.RequiredForIssuance -eq $true
  })
}