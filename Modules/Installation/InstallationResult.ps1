# ============================================================
# INSTALLATION RESULT
# ============================================================

function New-ApplicationInstallationResult {
  param(
    [Parameter(Mandatory)]
    [ValidateSet("Installed", "Skipped", "Failed")]
    [string]$Status,

    [Parameter(Mandatory)]
    [string]$ApplicationName,

    [string]$Message
  )

  if ([string]::IsNullOrWhiteSpace($Message)) {
    $Message = switch ($Status) {
      "Installed" {
        "$ApplicationName installed successfully."
      }

      "Skipped" {
        "$ApplicationName installation was skipped."
      }

      default {
        "$ApplicationName installation failed."
      }
    }
  }

  return [PSCustomObject]@{
    Status          = $Status
    ApplicationName = $ApplicationName
    Message         = $Message
  }
}

function ConvertTo-ApplicationInstallationResult {
  param(
    [AllowNull()]
    [object]$Result,

    [Parameter(Mandatory)]
    [string]$ApplicationName
  )

  if ($Result -is [bool]) {
    if ($Result) {
      return New-ApplicationInstallationResult -Status "Installed" -ApplicationName $ApplicationName
    }

    return New-ApplicationInstallationResult -Status "Failed" -ApplicationName $ApplicationName
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
      "INSTALLED" {
        return New-ApplicationInstallationResult -Status "Installed" -ApplicationName $ApplicationName -Message $Message
      }

      "SKIPPED" {
        return New-ApplicationInstallationResult -Status "Skipped" -ApplicationName $ApplicationName -Message $Message
      }

      default {
        return New-ApplicationInstallationResult -Status "Failed" -ApplicationName $ApplicationName -Message $Message
      }
    }
  }

  return New-ApplicationInstallationResult -Status "Failed" -ApplicationName $ApplicationName -Message "$ApplicationName returned an invalid installation result."
}