# ============================================================
# UNINSTALLATION RESULT
# ============================================================

function New-ApplicationUninstallationResult {
  param(
    [Parameter(Mandatory)]
    [ValidateSet("Uninstalled", "Skipped", "Failed")]
    [string]$Status,

    [Parameter(Mandatory)]
    [string]$ApplicationName,

    [string]$Message
  )

  if ([string]::IsNullOrWhiteSpace($Message)) {
    $Message = switch ($Status) {
      "Uninstalled" {
        "$ApplicationName uninstalled successfully."
      }

      "Skipped" {
        "$ApplicationName uninstallation was skipped."
      }

      default {
        "$ApplicationName uninstallation failed."
      }
    }
  }

  return [PSCustomObject]@{
    Status          = $Status
    ApplicationName = $ApplicationName
    Message         = $Message
  }
}

function ConvertTo-ApplicationUninstallationResult {
  param(
    [AllowNull()]
    [object]$Result,

    [Parameter(Mandatory)]
    [string]$ApplicationName
  )

  if ($Result -is [bool]) {
    if ($Result) {
      return New-ApplicationUninstallationResult -Status "Uninstalled" -ApplicationName $ApplicationName
    }

    return New-ApplicationUninstallationResult -Status "Failed" -ApplicationName $ApplicationName
  }

  if (($null -ne $Result) -and ($null -ne $Result.PSObject.Properties["Status"])) {
    $SourceStatus = ([string]$Result.Status).Trim().ToUpperInvariant()

    $Message = if ($null -ne $Result.PSObject.Properties["Message"]) {
      [string]$Result.Message
    }

    else {
      ""
    }

    switch ($SourceStatus) {
      "UNINSTALLED" {
        return New-ApplicationUninstallationResult -Status "Uninstalled" -ApplicationName $ApplicationName -Message $Message
      }

      "SKIPPED" {
        return New-ApplicationUninstallationResult -Status "Skipped" -ApplicationName $ApplicationName -Message $Message
      }

      default {
        return New-ApplicationUninstallationResult -Status "Failed" -ApplicationName $ApplicationName -Message $Message
      }
    }
  }

  return New-ApplicationUninstallationResult -Status "Failed" -ApplicationName $ApplicationName -Message "$ApplicationName returned an invalid uninstallation result."
}