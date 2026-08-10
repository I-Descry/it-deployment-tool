# ============================================================
# INSTALLER DIRECTORY INITIALIZATION
# ============================================================

function Initialize-InstallerDirectories {
  param([string]$RootPath = $script:ITDeploymentToolRoot)

  if ([string]::IsNullOrWhiteSpace($RootPath)) {
    throw "IT Deployment Tool root path is unavailable."
  }

  $RequiredDirectories = @(
    "Installers",
    "Installers\EXE",
    "Installers\EXE\CrowdStrike",
    "Installers\EXE\SAP",
    "Installers\MSI",
    "Installers\ISO",
    "Installers\ISO\Office2024",
    "Installers\IMG",
    "Installers\IMG\Office2021LOP",
    "Installers\ZIP",
    "Installers\Scripts"
  )

  $CreatedDirectories = [System.Collections.Generic.List[string]]::new()
  $ExistingDirectories = [System.Collections.Generic.List[string]]::new()

  foreach ($RelativePath in $RequiredDirectories) {
    $FullPath = Join-Path $RootPath $RelativePath

    if (Test-Path -LiteralPath $FullPath -PathType Container) {
      [void]$ExistingDirectories.Add($RelativePath)
      continue
    }

    New-Item -ItemType Directory -Path $FullPath -Force -ErrorAction Stop | Out-Null

    [void]$CreatedDirectories.Add($RelativePath)
  }

  return [PSCustomObject]@{
    CreatedCount = $CreatedDirectories.Count
    ExistingCount = $ExistingDirectories.Count
    Created = @($CreatedDirectories)
    Existing = @($ExistingDirectories)
  }
}