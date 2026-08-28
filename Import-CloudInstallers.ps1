# ============================================================
# IT Deployment Tool - Cloud Installer Import
# ============================================================
# Not part of the tool itself (Start.ps1 is the real entry point). For any
# application without a configured cloud source (Config\CloudInstallerSources.json,
# not tracked in git since this repo is public), offline installer ZIPs
# still have to be downloaded manually (sign in, open the shared folder,
# click Download) rather than fetched automatically. This script only
# automates the step after that: matching each downloaded ZIP to the
# application it belongs to (via Config\Applications.json, the single
# source of truth for install paths) and extracting it into the correct
# Installers\ subfolder, so a technician does not have to work out where
# each ZIP goes by hand.
#
#   .\Import-CloudInstallers.ps1
#   .\Import-CloudInstallers.ps1 -SourceFolder "D:\Downloads"
#
# Each ZIP's filename (without extension, letters/digits only) is matched
# against either the application's own top-level installer subfolder name
# (e.g. a ZIP named "SAP.zip" for Installers\EXE\SAP\, however many levels
# of vendor-extracted nesting sit underneath it) or the application's Name
# in Applications.json (e.g. "WinMTR.zip" for the WinMTR entry). A generic
# top-level type folder (EXE, MSI, ISO, IMG, ZIP, Scripts) is never used
# as a match on its own, since several unrelated applications can share one.

param(
  [string]$SourceFolder = (Join-Path $env:USERPROFILE "Downloads")
)

$RepoRoot = $PSScriptRoot
$InstallersRoot = Join-Path $RepoRoot "Installers"
$AppsJsonPath = Join-Path $RepoRoot "Config\Applications.json"

if (-not (Test-Path -LiteralPath $AppsJsonPath -PathType Leaf)) {
  throw "Config\Applications.json was not found under $RepoRoot."
}

if (-not (Test-Path -LiteralPath $SourceFolder -PathType Container)) {
  throw "Source folder not found: $SourceFolder"
}

# Reuses Get-CloudInstallerDestinationDirectory from the app's own
# automatic cloud-fetch module, so the "which folder does this
# application's package belong in" logic exists in exactly one place.
. (Join-Path $RepoRoot "Modules\Installation\CloudInstallerFetch.ps1")

$Applications = Get-Content -LiteralPath $AppsJsonPath -Raw | ConvertFrom-Json

function Get-CloudImportMatchKey {
  param([string]$Text)
  return ([string]$Text -replace '[^A-Za-z0-9]', '').ToLowerInvariant()
}

$DestinationsByKey = @{}
foreach ($Application in $Applications) {
  $DestinationDir = Get-CloudInstallerDestinationDirectory -Application $Application -InstallersRoot $InstallersRoot
  if ([string]::IsNullOrWhiteSpace($DestinationDir)) { continue }

  $DestinationsByKey[(Get-CloudImportMatchKey $Application.Name)] = $DestinationDir

  $FolderLeaf = Split-Path -Path $DestinationDir -Leaf
  if ($FolderLeaf -notin $script:GoogleDriveTypeFolderNames) {
    $DestinationsByKey[(Get-CloudImportMatchKey $FolderLeaf)] = $DestinationDir
  }
}

$Zips = @(Get-ChildItem -LiteralPath $SourceFolder -Filter "*.zip" -File -ErrorAction SilentlyContinue)

if ($Zips.Count -eq 0) {
  Write-Host "No .zip files found in $SourceFolder." -ForegroundColor Yellow
  return
}

$MatchedCount = 0
$Unmatched = @()

foreach ($Zip in $Zips) {
  $Key = Get-CloudImportMatchKey $Zip.BaseName

  if (-not $DestinationsByKey.ContainsKey($Key)) {
    $Unmatched += $Zip.Name
    continue
  }

  $DestinationDir = $DestinationsByKey[$Key]

  # Each ZIP wraps the app's own folder (e.g. "SAP.zip" contains a
  # top-level "SAP\" folder), so extracting into the parent of the
  # destination lets that wrapper folder recreate the destination
  # exactly, rather than nesting it one level too deep.
  $ParentDir = Split-Path -Path $DestinationDir -Parent

  if (-not (Test-Path -LiteralPath $ParentDir)) {
    New-Item -ItemType Directory -Path $ParentDir -Force | Out-Null
  }

  Write-Host "Extracting $($Zip.Name) -> $DestinationDir" -ForegroundColor Cyan
  Expand-Archive -LiteralPath $Zip.FullName -DestinationPath $ParentDir -Force
  $MatchedCount++
}

Write-Host ""
Write-Host "Extracted $MatchedCount of $($Zips.Count) zip file(s) into Installers\." -ForegroundColor Green

if ($Unmatched.Count -gt 0) {
  Write-Host "No matching application found for:" -ForegroundColor Yellow
  foreach ($Name in $Unmatched) {
    Write-Host "  - $Name" -ForegroundColor Yellow
  }
  Write-Host "Rename these to match either the installer's subfolder name or the application's Name in Config\Applications.json, then re-run." -ForegroundColor Yellow
}
