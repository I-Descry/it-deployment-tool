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
  # Reads Get-VisibleApplications, not $script:Applications directly, so Select All in Employee mode never selects an app from a hidden category that was never shown -- the install queue reads whatever ends up Selected here.
  foreach ($Application in (Get-VisibleApplications)) {
    $Application.Selected = $true
  }
}

function Clear-AllApplications {
  # Deliberately clears every application, not just Get-VisibleApplications -- unlike Select All/Recommended, a full reset is the one operation where clearing more than what's currently shown is still correct (and safer) rather than a scoping bug.
  foreach ($Application in $script:Applications) {
    $Application.Selected = $false
  }
}

function Select-RecommendedApplications {
  $RecommendedCount = 0

  foreach ($Application in (Get-VisibleApplications)) {
    $IsRecommended = (
      $Application.Recommended -eq $true
    )

    $Application.Selected = $IsRecommended

    if ($IsRecommended) {
      $RecommendedCount++
    }
  }

  return $RecommendedCount
}