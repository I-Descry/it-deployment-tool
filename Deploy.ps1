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

$RepoZipUrl = "https://github.com/I-Descry/it-deployment-tool/archive/refs/heads/main.zip"
$DestinationRoot = Join-Path $env:USERPROFILE "Desktop\IT Deployment Tool"
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

Move-Item -LiteralPath $ExtractedFolder.FullName -Destination $DestinationRoot

Remove-Item -LiteralPath $TempZipPath -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $TempExtractPath -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Ready at $DestinationRoot" -ForegroundColor Green
Write-Host "Launching..." -ForegroundColor Cyan

& (Join-Path $DestinationRoot "Start.ps1") -Gui
