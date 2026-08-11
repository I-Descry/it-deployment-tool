# ============================================================
# ZIP INSTALLER
# ============================================================

function Get-ZipPackagePath {
  param(
    [Parameter(Mandatory)]
    [PSCustomObject]$Application
  )

  return Get-OfflineInstallerPath -Application $Application
}

function Test-ZipDeploymentPackage {
  param(
    [Parameter(Mandatory)]
    [PSCustomObject]$Application
  )

  $PackagePath = Get-ZipPackagePath -Application $Application
  
  if (-not (Test-Path -LiteralPath $PackagePath -PathType Leaf)) {
    return [PSCustomObject]@{
      Valid   = $false
      Message = "ZIP package was not found."
    }
  }

  if (-not [System.IO.Path]::GetExtension($PackagePath).Equals(".zip", [System.StringComparison]::OrdinalIgnoreCase)) {
    return [PSCustomObject]@{
      Valid   = $false
      Message = "Configured package is not a ZIP file."
    }
  }

  $ExtractedInstallerPath = [string]$Application.ExtractedInstallerPath

  if ([string]::IsNullOrWhiteSpace($ExtractedInstallerPath)) {
    return [PSCustomObject]@{
      Valid   = $false
      Message = "ExtractedInstallerPath is not configured."
    }
  }

  $ExtractedInstallType = ([string]$Application.ExtractedInstallType).Trim().ToUpperInvariant()

  if ($ExtractedInstallType -notin @("EXE", "MSI")) {
    return [PSCustomObject]@{
      Valid   = $false
      Message = "ExtractedInstallType must be EXE or MSI."
    }
  }

  $ExpectedExtension = switch ($ExtractedInstallType) {
    "EXE" { ".exe" }
    "MSI" { ".msi" }
  }

  $ConfiguredExtension = [System.IO.Path]::GetExtension($ExtractedInstallerPath)

  if (-not $ConfiguredExtension.Equals($ExpectedExtension,[System.StringComparison]::OrdinalIgnoreCase)) {
    return [PSCustomObject]@{
      Valid   = $false
      Message = ("Extracted installer extension does not match {0}." -f $ExtractedInstallType)
    }
  }

  try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue

    $Archive = [System.IO.Compression.ZipFile]::OpenRead($PackagePath)

    try {
      foreach ($Entry in $Archive.Entries) {
        $EntryPath = $Entry.FullName.Replace("/", "\")

        if ([System.IO.Path]::IsPathRooted($EntryPath)) {
          return [PSCustomObject]@{
            Valid   = $false
            Message = "ZIP package contains an unsafe path."
          }
        }

        $Segments = @($EntryPath.Split([char[]]@("\"),[System.StringSplitOptions]::RemoveEmptyEntries))

        if ($Segments -contains "..") {
          return [PSCustomObject]@{
            Valid   = $false
            Message = "ZIP package contains an unsafe path."
          }
        }
      }

      $ExpectedEntry = ($ExtractedInstallerPath.Replace("\","/")).TrimStart("/").TrimEnd("/")
      $InstallerEntry = @($Archive.Entries | Where-Object {
        $ArchiveEntryPath = ($_.FullName.Replace("\", "/")).TrimStart("/").TrimEnd("/")

        $ArchiveEntryPath -ieq $ExpectedEntry
      })

      if ($InstallerEntry.Count -ne 1) {
        return [PSCustomObject]@{
          Valid     = $false
          Message   = "Configured installer was not found inside the ZIP package."
        }
      }
    }

    finally {
      $Archive.Dispose()
    }
  }

  catch {
    return [PSCustomObject]@{
      Valid   = $false
      Message = ("ZIP package could not be read: {0}" -f $_.Exception.Message)
    }
  }

  return [PSCustomObject]@{
    Valid                   = $true
    Message                 = "ZIP deployment package is valid."
    PackagePath            = $PackagePath
    ExtractedInstallerPath  = $ExtractedInstallerPath
    ExtractedInstallType    = $ExtractedInstallType
  }
}

function Expand-ZipDeploymentPackage {
  param(
    [Parameter(Mandatory)]
    [PSCustomObject]$Application
  )

  $PackageTest = Test-ZipDeploymentPackage -Application $Application

  if (-not $PackageTest.Valid) {
    throw $PackageTest.Message
  }

  $ExtractionRoot = Join-Path $env:TEMP "ITDeploymentTool\ZIP"

  New-Item -ItemType Directory -Path $ExtractionRoot -Force -ErrorAction Stop | Out-Null

  $ExtractionPath = Join-Path $ExtractionRoot ([guid]::NewGuid().ToString("N"))

  try {
    Expand-Archive -LiteralPath $PackageTest.PackagePath -DestinationPath $ExtractionPath -Force -ErrorAction Stop

    $InstallerPath = Join-Path $ExtractionPath $PackageTest.ExtractedInstallerPath

    if (-not (Test-Path -LiteralPath $InstallerPath -PathType Leaf)) {
      throw "Extracted installer was not found after extraction."
    }

    return [PSCustomObject]@{
      ExtractionPath = $ExtractionPath
      InstallerPath  = $InstallerPath
      InstallType    = $PackageTest.ExtractedInstallType
    }
  }

  catch {
    if (Test-Path -LiteralPath $ExtractionPath) {
      Remove-Item -LiteralPath $ExtractionPath -Recurse -Force -ErrorAction SilentlyContinue
    }

    throw
  }
}

function Remove-ZipDeploymentExtraction {
  param(
    [Parameter(Mandatory)]
    [string]$ExtractionPath
  )

  $ExtractionRoot = Join-Path $env:TEMP "ITDeploymentTool\ZIP"

  $RootFullPath = [System.IO.Path]::GetFullPath($ExtractionRoot).TrimEnd("\") + "\"
  $TargetFullPath = [System.IO.Path]::GetFullPath($ExtractionPath)

  if (-not $TargetFullPath.StartsWith($RootFullPath, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to remove a path outside the ZIP extraction directory."
  }

  if (Test-Path -LiteralPath $TargetFullPath) {
    Remove-Item -LiteralPath $TargetFullPath -Recurse -Force -ErrorAction Stop
  }
}

function Install-ApplicationFromZip {
  param(
    [Parameter(Mandatory)]
    [PSCustomObject]$Application
  )

  $Extraction = $null

  try {
    $Extraction = Expand-ZipDeploymentPackage -Application $Application

    $ExtractedApplication = [PSCustomObject]@{
      Name                  = $Application.Name
      DetectionName         = $Application.DetectionName
      InstallType           = $Extraction.InstallType
      InstallerPath         = $Application.ExtractedInstallerPath
      ResolvedInstallerPath = $Extraction.InstallerPath
      SilentArguments       = $Application.SilentArguments
      SuccessExitCodes      = @($Application.SuccessExitCodes)
      RebootExitCodes       = @($Application.RebootExitCodes)
    }

    switch ($Extraction.InstallType) {
      "EXE" {
        return Install-ApplicationWithExe -Application $ExtractedApplication
      }

      "MSI" {
        return Install-ApplicationWithMsi -Application $ExtractedApplication
      }

      default {
        throw ("Unsupported extracted installer type: {0}" -f $Extraction.InstallType)
      }
    }
  }

  catch {
    Write-Host
    Write-Host ("{0} ZIP installation failed: {1}" -f $Application.Name, $_.Exception.Message) -ForegroundColor Red

    Write-DeploymentLog -Message ("{0} ZIP installation failed: {1}" -f $Application.Name, $_.Exception.Message) -Level "ERROR"

    return $false
  }

  finally {
    if ($null -ne $Extraction -and -not [string]::IsNullOrWhiteSpace([string]$Extraction.ExtractionPath)) {
      try {
        Remove-ZipDeploymentExtraction -ExtractionPath $Extraction.ExtractionPath
      }

      catch {
        Write-DeploymentLog -Message ("{0} ZIP temporary extraction cleanup failed: {1}" -f $Application.Name, $_.Exception.Message) -Level "WARNING"
      }
    }
  }
}