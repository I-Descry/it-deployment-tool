# ============================================================
# APPLICATION SELECTION
# ============================================================

function Toggle-ApplicationSelection {
  param(
    [int]$Number
  )

  $Application = Get-ApplicationByNumber -Number $Number

  if ($null -eq $Application) {
    return $false
  }

  $Application.Selected = -not $Application.Selected

  return $true
}

function Select-AllApplications {
  foreach ($Application in $script:Applications) {
    $Application.Selected = $true
  }
}

function Clear-AllApplications {
  foreach ($Application in $script:Applications) {
    $Application.Selected = $false
  }
}
