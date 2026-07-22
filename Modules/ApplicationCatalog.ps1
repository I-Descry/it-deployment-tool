# ============================================================
# APPLICATION CATALOG
# ============================================================

# Stores the application database while the tool is running
$script:Applications = @()

# Connects menu numbers to application objects
$script:ApplicationMap = @{}

function Initialize-Applications {

  $ApplicationPath = Join-Path $PSScriptRoot "..\Config\Applications.json"

  $script:Applications = Get-Content $ApplicationPath -Raw | ConvertFrom-Json

  foreach ($Application in $script:Applications) {
    $Application | Add-Member -MemberType NoteProperty -Name Selected -Value $false
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