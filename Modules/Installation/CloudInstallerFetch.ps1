# ============================================================
# CLOUD INSTALLER FETCH
# ============================================================
# Automatic fetch-before-install for the handful of applications whose
# offline packages are too large to keep in this public git repo (CrowdStrike,
# both Office types, both SAP GUI versions). Company OneDrive could not be
# used for this (the tenant blocks both anonymous "anyone with the link"
# access and every unattended Microsoft Graph auth path -- app-only and
# delegated device-code both required admin approval that was confirmed not
# available), so the source is a personal Google Drive folder shared as
# "anyone with the link" instead.
#
# The mapping of application Name -> Google Drive share URL lives in
# Config\CloudInstallerSources.json, which is deliberately NOT
# Config\Applications.json and NOT tracked in git (see .gitignore) --
# this repository's GitHub remote is public, so a share link committed into
# Applications.json would let anyone read the repo download these licensed
# installers. A missing CloudInstallerSources.json is not an error; it just
# means no application has a configured cloud source, exactly like a device
# with no CrowdStrike Readme.txt has no configured CrowdStrike credentials.

function Get-CloudInstallerSources {
  if ($null -ne $script:CloudInstallerSourcesCache) {
    return $script:CloudInstallerSourcesCache
  }

  $SourcesPath = Join-Path $script:ITDeploymentToolRoot "Config\CloudInstallerSources.json"

  if (-not (Test-Path -LiteralPath $SourcesPath -PathType Leaf)) {
    $script:CloudInstallerSourcesCache = [PSCustomObject]@{}
    return $script:CloudInstallerSourcesCache
  }

  try {
    $script:CloudInstallerSourcesCache = Get-Content -LiteralPath $SourcesPath -Raw | ConvertFrom-Json
  }
  catch {
    Write-DeploymentLog -Message "Config\CloudInstallerSources.json could not be parsed: $($_.Exception.Message)" -Level "WARNING"
    $script:CloudInstallerSourcesCache = [PSCustomObject]@{}
  }

  return $script:CloudInstallerSourcesCache
}

function Get-CloudInstallerUrl {
  param(
    [Parameter(Mandatory)]
    [PSCustomObject]$Application
  )

  $Sources = Get-CloudInstallerSources
  $Property = $Sources.PSObject.Properties[$Application.Name]

  if ($null -eq $Property) {
    return $null
  }

  return [string]$Property.Value
}

function Test-CloudInstallerConfigured {
  param(
    [Parameter(Mandatory)]
    [PSCustomObject]$Application
  )

  return -not [string]::IsNullOrWhiteSpace((Get-CloudInstallerUrl -Application $Application))
}

function Get-GoogleDriveFileIdFromUrl {
  param(
    [Parameter(Mandatory)]
    [string]$Url
  )

  if ($Url -match '/d/(?<id>[0-9A-Za-z_-]+)') {
    return $Matches['id']
  }

  if ($Url -match '[?&]id=(?<id>[0-9A-Za-z_-]+)') {
    return $Matches['id']
  }

  return $null
}

$script:GoogleDriveTypeFolderNames = @("EXE", "MSI", "ISO", "IMG", "ZIP", "Scripts")

function Get-CloudInstallerDestinationDirectory {
  # Shared by Invoke-CloudInstallerFetch (below) and the standalone
  # Import-CloudInstallers.ps1 script, so the "which folder does this
  # application's package belong in" logic exists in exactly one place.
  # Resolves to the top-level app-specific subfolder directly under the
  # type folder (e.g. "SAP" in "EXE\SAP\..."), not the installer file's
  # own immediate parent -- some vendor-extracted installers (SAP GUI)
  # nest the real .exe several folders deeper than that.
  param(
    [Parameter(Mandatory)]
    [PSCustomObject]$Application,

    [Parameter(Mandatory)]
    [string]$InstallersRoot
  )

  switch ($Application.InstallType) {
    "CrowdStrike" {
      return Join-Path $InstallersRoot "EXE\CrowdStrike"
    }
    "OfficeIso" {
      return Join-Path $InstallersRoot "ISO\Office2024"
    }
    "Office2021Img" {
      return Join-Path $InstallersRoot "IMG\Office2021LOP"
    }
  }

  foreach ($PathField in @("InstallerPath", "UninstallerPath")) {
    $RelativePath = $Application.$PathField
    if ([string]::IsNullOrWhiteSpace([string]$RelativePath)) { continue }

    $Segments = @($RelativePath -split '[\\/]' | Where-Object { $_ -ne "" })
    if ($Segments.Count -lt 2) { continue }

    $TypeFolder = $Segments[0]
    if ($TypeFolder -notin $script:GoogleDriveTypeFolderNames) { continue }

    if ($Segments.Count -ge 3) {
      return Join-Path $InstallersRoot (Join-Path $TypeFolder $Segments[1])
    }

    return Join-Path $InstallersRoot $TypeFolder
  }

  return $null
}

function Invoke-GoogleDriveFileDownload {
  # Google's own "file too large to scan for viruses" interstitial has to be
  # walked through in two requests: the first captures a session cookie plus
  # a per-request confirm token and uuid from a hidden form, and the second
  # (against drive.usercontent.google.com, not drive.google.com -- this
  # changed from the older documented endpoint) uses them to get the real
  # file. Verified against a real file from the user's actual Drive folder
  # before this was relied on anywhere.
  param(
    [Parameter(Mandatory)]
    [string]$FileId,

    [Parameter(Mandatory)]
    [string]$OutFile
  )

  $InitialHtmlPath = [System.IO.Path]::GetTempFileName()

  try {
    Invoke-WebRequest -Uri "https://drive.google.com/uc?export=download&id=$FileId" -OutFile $InitialHtmlPath -SessionVariable GoogleDriveSession -UseBasicParsing -TimeoutSec 60 | Out-Null

    $Content = Get-Content -LiteralPath $InitialHtmlPath -Raw

    $ConfirmToken = if ($Content -match 'name="confirm" value="(?<v>[^"]+)"') { $Matches['v'] } else { "t" }
    $Uuid = if ($Content -match 'name="uuid" value="(?<v>[^"]+)"') { $Matches['v'] } else { $null }

    $Uri = "https://drive.usercontent.google.com/download?id=$FileId&export=download&confirm=$ConfirmToken"
    if ($Uuid) { $Uri += "&uuid=$Uuid" }

    Invoke-WebRequest -Uri $Uri -OutFile $OutFile -WebSession $GoogleDriveSession -UseBasicParsing -TimeoutSec 3600 | Out-Null
  }
  finally {
    Remove-Item -LiteralPath $InitialHtmlPath -Force -ErrorAction SilentlyContinue
  }
}

function Invoke-CloudInstallerFetch {
  param(
    [Parameter(Mandatory)]
    [PSCustomObject]$Application
  )

  $Url = Get-CloudInstallerUrl -Application $Application

  if ([string]::IsNullOrWhiteSpace($Url)) {
    return [PSCustomObject]@{
      Status  = "Failed"
      Message = "No cloud installer source is configured for $($Application.Name)."
    }
  }

  $FileId = Get-GoogleDriveFileIdFromUrl -Url $Url

  if ([string]::IsNullOrWhiteSpace($FileId)) {
    return [PSCustomObject]@{
      Status  = "Failed"
      Message = "Could not parse a Google Drive file ID from the configured URL for $($Application.Name)."
    }
  }

  $InstallersRoot = Join-Path $script:ITDeploymentToolRoot "Installers"
  $DestinationDir = Get-CloudInstallerDestinationDirectory -Application $Application -InstallersRoot $InstallersRoot

  if ([string]::IsNullOrWhiteSpace($DestinationDir)) {
    return [PSCustomObject]@{
      Status  = "Failed"
      Message = "Could not determine a destination folder for $($Application.Name)."
    }
  }

  $TempZipPath = Join-Path $env:TEMP "$($FileId).zip"

  try {
    Write-DeploymentLog -Message "Downloading $($Application.Name) from its configured cloud source..." -Level "INFO"

    Invoke-GoogleDriveFileDownload -FileId $FileId -OutFile $TempZipPath

    if (-not (Test-Path -LiteralPath $TempZipPath -PathType Leaf)) {
      return [PSCustomObject]@{
        Status  = "Failed"
        Message = "Download of $($Application.Name) did not produce a file."
      }
    }

    # The ZIPs this project's technicians create wrap the app's own folder
    # (e.g. "SAP.zip" contains a top-level "SAP\" folder), so extracting
    # into the parent of the destination lets that wrapper folder recreate
    # the destination exactly, rather than nesting it one level too deep.
    $ParentDir = Split-Path -Path $DestinationDir -Parent

    if (-not (Test-Path -LiteralPath $ParentDir)) {
      New-Item -ItemType Directory -Path $ParentDir -Force | Out-Null
    }

    Expand-Archive -LiteralPath $TempZipPath -DestinationPath $ParentDir -Force

    Write-DeploymentLog -Message "$($Application.Name) fetched from its cloud source and extracted to $DestinationDir." -Level "SUCCESS"

    return [PSCustomObject]@{
      Status  = "Success"
      Message = "$($Application.Name) was downloaded from its configured cloud source."
    }
  }
  catch {
    Write-DeploymentLog -Message "Failed to fetch $($Application.Name) from its cloud source: $($_.Exception.Message)" -Level "ERROR"

    return [PSCustomObject]@{
      Status  = "Failed"
      Message = "Failed to download $($Application.Name): $($_.Exception.Message)"
    }
  }
  finally {
    Remove-Item -LiteralPath $TempZipPath -Force -ErrorAction SilentlyContinue
  }
}
