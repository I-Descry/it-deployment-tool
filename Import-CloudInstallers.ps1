# ============================================================
# IT Deployment Tool - Cloud Installer Import
# ============================================================
# Not part of the tool itself (Start.ps1 is the real entry point). The
# company OneDrive/SharePoint tenant disables "anyone with the link"
# sharing and there is no Azure AD app registration for unattended Graph
# API access, so offline installer ZIPs still have to be downloaded
# manually (sign in, open the shared folder, click Download) rather than
# fetched automatically per application. This script only automates the
# step after that: matching each downloaded ZIP to the application it
# belongs to (via Config\Applications.json, the single source of truth
# for install paths) and extracting it into the correct Installers\
# subfolder, so a technician does not have to work out where each ZIP
# goes by hand.
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

$Applications = Get-Content -LiteralPath $AppsJsonPath -Raw | ConvertFrom-Json

$TypeFolderNames = @("EXE", "MSI", "ISO", "IMG", "ZIP", "Scripts")

function Get-CloudImportMatchKey {
  param([string]$Text)
  return ([string]$Text -replace '[^A-Za-z0-9]', '').ToLowerInvariant()
}

# Build a lookup of match key -> destination folder from every configured
# InstallerPath/UninstallerPath, so this stays driven entirely by
# Applications.json rather than a separately-maintained mapping table.
# The destination is the top-level app-specific subfolder directly under
# the type folder (e.g. "SAP" in "EXE\SAP\..."), not the installer file's
# own immediate parent directory -- some vendor-extracted installers (SAP
# GUI) nest their real .exe several folders deeper (".../GUI/Windows/Win32/
# SapGuiSetup.exe"), and "SAP" is the folder a technician would sensibly
# zip as one unit, matching CLAUDE.md's own documented convention for
# multi-file applications ("Installers\EXE\SAP\").
$DestinationsByKey = @{}
foreach ($Application in $Applications) {
  foreach ($PathField in @("InstallerPath", "UninstallerPath")) {
    $RelativePath = $Application.$PathField
    if ([string]::IsNullOrWhiteSpace([string]$RelativePath)) { continue }

    $Segments = @($RelativePath -split '[\\/]' | Where-Object { $_ -ne "" })
    if ($Segments.Count -lt 2) { continue }

    $TypeFolder = $Segments[0]
    if ($TypeFolder -notin $TypeFolderNames) { continue }

    if ($Segments.Count -ge 3) {
      # A real app-specific subfolder sits between the type folder and the
      # installer file, however many levels of vendor nesting follow it.
      $SubFolder = $Segments[1]
      $DestinationDir = Join-Path $InstallersRoot (Join-Path $TypeFolder $SubFolder)
      $DestinationsByKey[(Get-CloudImportMatchKey $SubFolder)] = $DestinationDir
    }
    else {
      # The installer file sits directly in the type folder with no
      # app-specific subfolder -- only the application's own Name is a
      # safe match key here, since the type folder itself is shared by
      # unrelated applications.
      $DestinationDir = Join-Path $InstallersRoot $TypeFolder
    }

    $DestinationsByKey[(Get-CloudImportMatchKey $Application.Name)] = $DestinationDir
  }

  # CrowdStrike, Office LTSC 2024 (OfficeIso), and Office 2021 LOP (Office2021Img)
  # do not use InstallerPath at all -- their installer modules resolve a
  # hardcoded package directory instead (Get-CrowdStrikePackageDirectory,
  # Get-Office2024PackageDirectory-equivalent, Get-Office2021ImageDirectory).
  # Registered here by their real InstallType and the same hardcoded folder
  # each of those modules already uses, not a new convention.
  switch ($Application.InstallType) {
    "CrowdStrike" {
      $DestinationDir = Join-Path $InstallersRoot "EXE\CrowdStrike"
      $DestinationsByKey["crowdstrike"] = $DestinationDir
      $DestinationsByKey[(Get-CloudImportMatchKey $Application.Name)] = $DestinationDir
    }
    "OfficeIso" {
      $DestinationDir = Join-Path $InstallersRoot "ISO\Office2024"
      $DestinationsByKey["office2024"] = $DestinationDir
      $DestinationsByKey[(Get-CloudImportMatchKey $Application.Name)] = $DestinationDir
    }
    "Office2021Img" {
      $DestinationDir = Join-Path $InstallersRoot "IMG\Office2021LOP"
      $DestinationsByKey["office2021lop"] = $DestinationDir
      $DestinationsByKey[(Get-CloudImportMatchKey $Application.Name)] = $DestinationDir
    }
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

  if (-not (Test-Path -LiteralPath $DestinationDir)) {
    New-Item -ItemType Directory -Path $DestinationDir -Force | Out-Null
  }

  Write-Host "Extracting $($Zip.Name) -> $DestinationDir" -ForegroundColor Cyan
  Expand-Archive -LiteralPath $Zip.FullName -DestinationPath $DestinationDir -Force
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
