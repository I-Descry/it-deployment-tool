# ============================================================
# IT Deployment Tool - Remote Bootstrap
# ============================================================
# Not part of the tool itself (Start.ps1 is the real entry point, dot-sourcing
# Modules\ exactly as documented in CLAUDE.md). This script only fetches the
# current tool from GitHub onto the local disk and then launches it, so a
# technician at a remote device can run one line instead of manually cloning
# or copying files over:
#
#   irm https://raw.githubusercontent.com/I-Descry/it-deployment-tool/main/Deploy.ps1 | iex
#
# This only downloads what git already tracks (the scripts and Config\Applications.json,
# a few MB) -- the gitignored Installers\ binaries are NOT part of the repo and
# are not fetched by this script. Initialize-InstallerDirectories still creates
# the folder structure on first run; heavy offline installers (Office, SAP,
# CrowdStrike, etc.) still need to be copied in separately for the applications
# that require them, exactly as before.
#
# The launch below passes -DeleteOnClose, which is only ever set here: closing
# the GUI window on a device set up this way asks for confirmation, then
# permanently deletes this entire folder from that device (not the applications
# it installed, just the tool itself). A manually run .\Start.ps1 -Gui never
# gets this flag, so this dev repo (or anyone's manually cloned copy) never
# self-deletes.
#
# $env:USERPROFILE reflects whichever account this script's own process is
# running as, which is NOT the real target user when elevating a genuine
# standard local user required switching to a separate admin account (e.g. the
# Built-in Administrator) to get here -- in that case $env:USERPROFILE would
# be the Administrator's own profile, not the person this device is actually
# for. Get-InteractiveUserProfilePath resolves the real interactively
# logged-on user's own profile folder instead, so the tool lands on their
# Desktop, matching where a technician (and, if they never delete it, that
# user) would actually expect to find it.

function Get-InteractiveUserProfilePath {
  # Falls back to $env:USERPROFILE (this process's own account) if the real interactive user's profile can't be resolved for any reason, so bootstrapping still works either way.
  try {
    $InteractiveUserName = [string](Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop).UserName

    if ([string]::IsNullOrWhiteSpace($InteractiveUserName)) {
      return $env:USERPROFILE
    }

    $ShortUserName = $InteractiveUserName.Split('\')[-1]
    $UserAccount = Get-CimInstance -ClassName Win32_UserAccount -Filter "Name='$ShortUserName'" -ErrorAction Stop | Select-Object -First 1

    if ($null -eq $UserAccount) {
      return $env:USERPROFILE
    }

    $UserProfile = Get-CimInstance -ClassName Win32_UserProfile -Filter "SID='$($UserAccount.SID)'" -ErrorAction Stop | Select-Object -First 1

    if (($null -eq $UserProfile) -or [string]::IsNullOrWhiteSpace($UserProfile.LocalPath)) {
      return $env:USERPROFILE
    }

    return $UserProfile.LocalPath
  }
  catch {
    return $env:USERPROFILE
  }
}

$RepoZipUrl = "https://github.com/I-Descry/it-deployment-tool/archive/refs/heads/main.zip"
$DestinationRoot = Join-Path (Get-InteractiveUserProfilePath) "Desktop\IT Deployment Tool"
$TempZipPath = Join-Path $env:TEMP "it-deployment-tool-download.zip"
$TempExtractPath = Join-Path $env:TEMP "it-deployment-tool-extract"

Write-Host "Downloading the current IT Deployment Tool..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $RepoZipUrl -OutFile $TempZipPath -UseBasicParsing

if (Test-Path -LiteralPath $TempExtractPath) {
  Remove-Item -LiteralPath $TempExtractPath -Recurse -Force
}

Write-Host "Extracting..." -ForegroundColor Cyan
Expand-Archive -LiteralPath $TempZipPath -DestinationPath $TempExtractPath -Force

$ExtractedFolder = Get-ChildItem -LiteralPath $TempExtractPath -Directory | Select-Object -First 1

if ($null -eq $ExtractedFolder) {
  throw "The downloaded archive did not contain the expected folder."
}

if (Test-Path -LiteralPath $DestinationRoot) {
  Write-Host "Removing previous copy at $DestinationRoot..." -ForegroundColor Yellow
  Remove-Item -LiteralPath $DestinationRoot -Recurse -Force
}

# Move-Item never creates missing intermediate folders -- on a device where the target user's Desktop folder does not yet exist (e.g. a profile whose standard folders were never fully provisioned, or a broken OneDrive Known Folder Move redirection), this would otherwise fail with "Could not find a part of the path" while still being a non-terminating error by default, letting the script print "Ready"/"Launching" and only fail a second, more confusing time when it tries to launch a Start.ps1 that was never actually placed there.
$DestinationParent = Split-Path -Path $DestinationRoot -Parent

if (-not (Test-Path -LiteralPath $DestinationParent)) {
  New-Item -ItemType Directory -Path $DestinationParent -Force | Out-Null
}

Move-Item -LiteralPath $ExtractedFolder.FullName -Destination $DestinationRoot -ErrorAction Stop

Remove-Item -LiteralPath $TempZipPath -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $TempExtractPath -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Ready at $DestinationRoot" -ForegroundColor Green
Write-Host "Launching..." -ForegroundColor Cyan

# -ExecutionPolicy Bypass applies only to this one launched process, not to the device's actual policy setting -- without it, a fresh Windows machine whose execution policy defaults to Restricted would fail at this exact line after everything else downloaded and extracted successfully.
powershell.exe -ExecutionPolicy Bypass -File (Join-Path $DestinationRoot "Start.ps1") -Gui -DeleteOnClose
