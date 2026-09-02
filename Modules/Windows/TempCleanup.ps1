# ============================================================
# TEMP CLEANUP
# ============================================================
# Read-only scan and destructive cleanup of the well-known temp/cache locations shown on the Temp Cleanup screen (the current user's %TEMP%, C:\Windows\Temp, C:\Windows\Prefetch), following the same read-only-check vs. destructive-action split used throughout this app (e.g. InstallerPackageReadiness.ps1 vs. the installer modules).

function Get-TempCleanupTargetPaths {
  return [ordered]@{
    "User Temp"    = $env:TEMP
    "Windows Temp" = "C:\Windows\Temp"
    "Prefetch"     = "C:\Windows\Prefetch"
  }
}

function Format-TempCleanupSize {
  # Deliberately avoids the built-in [math]::Round-on-bytes shorthand used elsewhere in this app, since a size this small could round to "0 MB" and look like nothing was found.
  param(
    [Parameter(Mandatory)]
    [double]$Bytes
  )

  if ($Bytes -ge 1GB) {
    return "{0:N1} GB" -f ($Bytes / 1GB)
  }

  if ($Bytes -ge 1MB) {
    return "{0:N1} MB" -f ($Bytes / 1MB)
  }

  if ($Bytes -ge 1KB) {
    return "{0:N1} KB" -f ($Bytes / 1KB)
  }

  return "$([math]::Round($Bytes, 0)) bytes"
}

function Get-TempCleanupTargets {
  # Uses -ErrorAction SilentlyContinue with -ErrorVariable (not -ErrorAction Stop) so one inaccessible nested subfolder -- e.g. the WinSAT results folder under a real user's own %TEMP%, confirmed access-denied even to its owning user on this dev machine -- only skips that subfolder instead of aborting the entire location's scan. Accessible is only ever set to $false when NO files came back at all AND a scan error was recorded, which is what actually distinguishes "this whole location is denied" (Windows Temp/Prefetch without elevation) from "genuinely empty" or "mostly readable with one odd subfolder walled off".
  # Uses [Generic.List[object]]::new() rather than New-Object -- New-Object System.Collections.Generic.List[object] produces a list that throws "Argument types do not match" when later wrapped in @() on this PowerShell 5.1 build, a real, reproducible quirk InstallerPackageReadiness.ps1 already works around the same way.
  $Targets = [System.Collections.Generic.List[object]]::new()

  foreach ($Entry in (Get-TempCleanupTargetPaths).GetEnumerator()) {
    $Name = $Entry.Key
    $Path = $Entry.Value

    $FileCount = 0
    $TotalSizeBytes = 0
    $Accessible = $true
    $ErrorMessage = ""

    try {
      $ScanErrors = $null
      $Files = @(Get-ChildItem -LiteralPath $Path -Recurse -File -Force -ErrorAction SilentlyContinue -ErrorVariable ScanErrors)
      $FileCount = $Files.Count

      $SizeSum = ($Files | Measure-Object -Property Length -Sum).Sum

      if ($null -ne $SizeSum) {
        $TotalSizeBytes = $SizeSum
      }

      if ($FileCount -eq 0 -and $ScanErrors.Count -gt 0) {
        $Accessible = $false
        $ErrorMessage = $ScanErrors[0].Exception.Message
      }
    }
    catch {
      $Accessible = $false
      $ErrorMessage = $_.Exception.Message
    }

    [void]$Targets.Add([PSCustomObject]@{
      Name           = $Name
      Path           = $Path
      FileCount      = $FileCount
      TotalSizeBytes = $TotalSizeBytes
      SizeText       = Format-TempCleanupSize -Bytes $TotalSizeBytes
      Accessible     = $Accessible
      ErrorMessage   = $ErrorMessage
    })
  }

  return @($Targets)
}

function Remove-TempCleanupTarget {
  # Deletes files individually rather than one recursive Remove-Item, so a single locked/in-use file is skipped instead of aborting the whole location; only ever deletes files inside the target folder, never the folder itself, since Windows expects %TEMP%/C:\Windows\Temp/C:\Windows\Prefetch to keep existing.
  param(
    [Parameter(Mandatory)]
    [PSCustomObject]$Target
  )

  if (-not $Target.Accessible) {
    return [PSCustomObject]@{
      Name         = $Target.Name
      Status       = "Failed"
      DeletedCount = 0
      SkippedCount = 0
      DeletedBytes = 0
      Message      = "$($Target.Name) could not be accessed: $($Target.ErrorMessage)"
    }
  }

  try {
    # SilentlyContinue (not Stop), same reasoning as Get-TempCleanupTargets: an inaccessible nested subfolder must not abort re-scanning the rest of an otherwise-deletable location.
    $Files = @(Get-ChildItem -LiteralPath $Target.Path -Recurse -File -Force -ErrorAction SilentlyContinue)
  }
  catch {
    return [PSCustomObject]@{
      Name         = $Target.Name
      Status       = "Failed"
      DeletedCount = 0
      SkippedCount = 0
      DeletedBytes = 0
      Message      = "$($Target.Name) could not be re-scanned before deletion: $($_.Exception.Message)"
    }
  }

  $DeletedCount = 0
  $SkippedCount = 0
  $DeletedBytes = 0

  foreach ($File in $Files) {
    try {
      $FileLength = $File.Length
      Remove-Item -LiteralPath $File.FullName -Force -ErrorAction Stop
      $DeletedCount++
      $DeletedBytes += $FileLength
    }
    catch {
      $SkippedCount++
    }
  }

  $SizeText = Format-TempCleanupSize -Bytes $DeletedBytes

  $Message = if ($SkippedCount -eq 0) {
    "$($Target.Name): deleted $DeletedCount file(s), freed $SizeText."
  }
  else {
    "$($Target.Name): deleted $DeletedCount file(s) ($SizeText freed), skipped $SkippedCount locked file(s)."
  }

  return [PSCustomObject]@{
    Name         = $Target.Name
    Status       = "Cleaned"
    DeletedCount = $DeletedCount
    SkippedCount = $SkippedCount
    DeletedBytes = $DeletedBytes
    Message      = $Message
  }
}
