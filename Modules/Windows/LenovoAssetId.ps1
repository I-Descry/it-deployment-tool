# ============================================================
# LENOVO ASSET ID (WinAIA)
# ============================================================
# WinAIA (Windows Asset ID Access) is a Lenovo ThinkPad-only utility that
# reads and writes a handful of asset-tracking fields (owner, department,
# warranty, etc.) into BIOS storage. It is installed separately (see the
# "Lenovo Windows Asset ID Utility" catalog entry, InstallType Exe) which
# extracts WinAIA.exe / WinAIA64.exe and a template Sample.txt to
# C:\DRIVERS\WINAIA. This module only edits that Sample.txt and invokes
# WinAIA against it -- confirmed against the exact workflow already tested
# by hand: edit Sample.txt, then from C:\DRIVERS\WINAIA run
# `WinAIA64.exe -set-from-file Sample.txt`, which opens WinAIA's own
# confirmation dialog before it actually writes anything.

$script:DeploymentAssetIdDirectory = "C:\DRIVERS\WINAIA"
$script:DeploymentAssetIdSampleFile = "Sample.txt"

# Two groups, matching Sample.txt's own layout (a blank line separates
# them) -- every other field WinAIA's template ships with is deliberately
# left out, matching the exact trimmed-down Sample.txt already confirmed
# to work with `-set-from-file`.
$script:DeploymentAssetIdOwnerKeys = @(
  "OWNERDATA.OWNERNAME"
  "OWNERDATA.DEPARTMENT"
  "OWNERDATA.LOCATION"
  "OWNERDATA.PHONE_NUMBER"
  "OWNERDATA.OWNERPOSITION"
)
$script:DeploymentAssetIdAssetKeys = @(
  "USERASSETDATA.PURCHASE_DATE"
  "USERASSETDATA.LAST_INVENTORIED"
  "USERASSETDATA.WARRANTY_END"
  "USERASSETDATA.WARRANTY_DURATION"
  "USERASSETDATA.AMOUNT"
  "USERASSETDATA.ASSET_NUMBER"
)

function Get-DeploymentAssetIdFieldNames {
  # Returns every supported field name, in file order, for callers that need
  # the full set without caring about the owner/asset grouping.
  return @($script:DeploymentAssetIdOwnerKeys) + @($script:DeploymentAssetIdAssetKeys)
}

function Get-WinAiaExecutablePath {
  # Prefers the 64-bit binary when both exist, matching this app's existing
  # convention elsewhere of preferring the 64-bit path on modern systems.
  # Selecting by which file actually exists (rather than assuming based on
  # OS architecture) is deliberate: the installer is described as always
  # extracting both binaries regardless of host architecture.
  $Candidates = @(
    (Join-Path $script:DeploymentAssetIdDirectory "WinAIA64.exe")
    (Join-Path $script:DeploymentAssetIdDirectory "WinAIA.exe")
  )

  foreach ($Candidate in $Candidates) {
    if (Test-Path -LiteralPath $Candidate -PathType Leaf) {
      return $Candidate
    }
  }

  return $null
}

function Get-DeploymentAssetIdFields {
  # Reads the current values out of Sample.txt (if it already exists from a
  # previous save) so the GUI can show what is already set, matching how
  # every other card on this screen shows current state before letting a
  # technician change it. Read-only; never creates or modifies the file.
  $Fields = @{}

  foreach ($Key in (Get-DeploymentAssetIdFieldNames)) {
    $Fields[$Key] = ""
  }

  $SamplePath = Join-Path $script:DeploymentAssetIdDirectory $script:DeploymentAssetIdSampleFile

  if (-not (Test-Path -LiteralPath $SamplePath -PathType Leaf)) {
    return $Fields
  }

  foreach ($Line in (Get-Content -LiteralPath $SamplePath -ErrorAction SilentlyContinue)) {
    $EqualsIndex = $Line.IndexOf("=")

    if ($EqualsIndex -lt 1) {
      continue
    }

    $Key = $Line.Substring(0, $EqualsIndex).Trim()
    $Value = $Line.Substring($EqualsIndex + 1).Trim()

    if ($Fields.ContainsKey($Key)) {
      $Fields[$Key] = $Value
    }
  }

  return $Fields
}

function Set-DeploymentAssetIdFields {
  # Writes Sample.txt with ONLY the 11 supported fields (every other field
  # WinAIA's own template ships with is left out entirely), in the exact
  # key order and owner/blank-line/asset grouping already confirmed to work
  # with `-set-from-file`. Every field is optional; a blank value writes as
  # "KEY=" with nothing after it, same as WinAIA's own template does for an
  # unset field. Plain ASCII, no BOM: this is an old-style Windows config
  # text format, and a stray UTF-8 BOM on the first line is a common way to
  # break a simple line-by-line KEY=VALUE parser -- not independently
  # verified against WinAIA itself, since that requires the real tool, but
  # the safer default of the two.
  param(
    [Parameter(Mandatory)]
    [hashtable]$Fields
  )

  if (-not (Test-Path -LiteralPath $script:DeploymentAssetIdDirectory -PathType Container)) {
    throw "$script:DeploymentAssetIdDirectory does not exist. Install the Lenovo Windows Asset ID Utility first."
  }

  $Lines = [System.Collections.Generic.List[string]]::new()

  foreach ($Key in $script:DeploymentAssetIdOwnerKeys) {
    [void]$Lines.Add("$Key=$($Fields[$Key])")
  }

  [void]$Lines.Add("")

  foreach ($Key in $script:DeploymentAssetIdAssetKeys) {
    [void]$Lines.Add("$Key=$($Fields[$Key])")
  }

  $SamplePath = Join-Path $script:DeploymentAssetIdDirectory $script:DeploymentAssetIdSampleFile
  Set-Content -LiteralPath $SamplePath -Value $Lines -Encoding ASCII -ErrorAction Stop

  return $SamplePath
}

function Invoke-DeploymentAssetIdWrite {
  # Launches WinAIA against the Sample.txt just written. WinAIA opens its
  # own confirmation dialog before actually committing anything to BIOS --
  # this is a real, separate, un-scriptable UI step the technician must
  # complete themselves; -Wait only waits for WinAIA's process to exit,
  # it does not (and cannot safely) click through that dialog on its own
  # behalf. Exit code semantics were not confirmed by hand-testing, so this
  # reports the raw exit code rather than asserting success/failure beyond
  # what is actually known: 0 is treated as success (the conventional
  # default for a Windows console/GUI tool), anything else is reported back
  # verbatim for the technician to judge against what WinAIA's own dialog
  # showed.
  $WinAiaPath = Get-WinAiaExecutablePath

  if ($null -eq $WinAiaPath) {
    return [PSCustomObject]@{
      Status  = "Failed"
      Message = "WinAIA.exe / WinAIA64.exe was not found in $script:DeploymentAssetIdDirectory. Install the Lenovo Windows Asset ID Utility first."
    }
  }

  $LoggingCommand = Get-Command -Name "Write-DeploymentLog" -ErrorAction SilentlyContinue

  try {
    $Process = Start-Process -FilePath $WinAiaPath -ArgumentList "-set-from-file", $script:DeploymentAssetIdSampleFile `
      -WorkingDirectory $script:DeploymentAssetIdDirectory -Wait -PassThru -ErrorAction Stop

    if ($null -ne $LoggingCommand) {
      Write-DeploymentLog -Message ("WinAIA asset ID write ran, exit code {0}." -f $Process.ExitCode) -Level "INFO"
    }

    if ($Process.ExitCode -eq 0) {
      return [PSCustomObject]@{
        Status  = "Applied"
        Message = "WinAIA finished (exit code 0). Confirm in WinAIA's own dialog that the values were accepted."
      }
    }

    return [PSCustomObject]@{
      Status  = "Failed"
      Message = "WinAIA exited with code $($Process.ExitCode). This may just mean the confirmation dialog was declined -- check what WinAIA itself reported."
    }
  }
  catch {
    if ($null -ne $LoggingCommand) {
      Write-DeploymentLog -Message ("WinAIA asset ID write failed: {0}" -f $_.Exception.Message) -Level "ERROR"
    }

    return [PSCustomObject]@{
      Status  = "Failed"
      Message = $_.Exception.Message
    }
  }
}
