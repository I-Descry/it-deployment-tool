# ============================================================
# MICROSOFT TEAMS
# ============================================================

function Get-MicrosoftTeamsCurrentUserPackage {
  [CmdletBinding()]
  param()

  $GetAppxPackageCommand = Get-Command -Name "Get-AppxPackage" -ErrorAction SilentlyContinue
  
  if ($null -eq $GetAppxPackageCommand) {
    return $null
  }

  try {
    return Get-AppxPackage -Name "MSTeams" -ErrorAction Stop | Select-Object -First 1
  }
  
  catch {
    return $null
  }
}

function Get-MicrosoftTeamsProvisionedPackage {
  [CmdletBinding()]
  param()

  $GetProvisionedPackageCommand = Get-Command -Name "Get-AppxProvisionedPackage" -ErrorAction SilentlyContinue

  if ($null -eq $GetProvisionedPackageCommand) {
    return $null
  }

  try {
    return Get-AppxProvisionedPackage -Online -ErrorAction Stop | Where-Object {
      $_.DisplayName -eq "MSTeams"
    } | Select-Object -First 1
  }

  catch {
    return $null
  }
}

function Test-MicrosoftTeamsCurrentUserInstalled {
  [CmdletBinding()]
  param()

  $TeamsPackage = Get-MicrosoftTeamsCurrentUserPackage

  return ($null -ne $TeamsPackage)
}

function Test-MicrosoftTeamsProvisioned {
  [CmdletBinding()]
  param()

  $TeamsPackage = Get-MicrosoftTeamsProvisionedPackage

  return ($null -ne $TeamsPackage)
}

function Test-MicrosoftTeamsInstalled {
  [CmdletBinding()]
  param()

  # For deployment purposes, Teams must be provisioned for existing and future Windows users.
  return [bool](Test-MicrosoftTeamsProvisioned)
}

function Get-MicrosoftTeamsDetectionResult {
  [CmdletBinding()]
  param()

  $CurrentUserPackage = Get-MicrosoftTeamsCurrentUserPackage
  $ProvisionedPackage = Get-MicrosoftTeamsProvisionedPackage

  return [PSCustomObject]@{
    CurrentUserInstalled = ($null -ne $CurrentUserPackage)
    CurrentUserVersion   = if ($null -ne $CurrentUserPackage) {
      [string]$CurrentUserPackage.Version
    }
    else {
      $null
    }
    Provisioned          = ($null -ne $ProvisionedPackage)
    ProvisionedVersion   = if ($null -ne $ProvisionedPackage) {
      [string]$ProvisionedPackage.Version
    }
    else {
      $null
    }
    
    DeploymentReady      = ($null -ne $ProvisionedPackage)
  }
}

# ============================================================
# MICROSOFT TEAMS BOOTSTRAPPER
# ============================================================

function Get-MicrosoftTeamsBootstrapperUri {
  [CmdletBinding()]
  param()

  return [Uri]("https://go.microsoft.com/fwlink/?clcid=0x409&linkid=2243204")
}

function Get-MicrosoftTeamsBootstrapperDirectory {
  [CmdletBinding()]
  param()

  return Join-Path $env:TEMP "ITDeploymentTool\MicrosoftTeams"
}

function Get-MicrosoftTeamsBootstrapperPath {
  [CmdletBinding()]
  param()

  $BootstrapperDirectory = Get-MicrosoftTeamsBootstrapperDirectory

  return Join-Path $BootstrapperDirectory "teamsbootstrapper.exe"
}

function Save-MicrosoftTeamsBootstrapper {
  [CmdletBinding()]
  param()

  $BootstrapperDirectory = Get-MicrosoftTeamsBootstrapperDirectory
  $BootstrapperPath = Get-MicrosoftTeamsBootstrapperPath

  if (-not (Test-Path -LiteralPath $BootstrapperDirectory -PathType Container)) {
    New-Item -Path $BootstrapperDirectory -ItemType Directory -Force -ErrorAction Stop | Out-Null
  }

  Remove-Item -LiteralPath $BootstrapperPath -Force -ErrorAction SilentlyContinue
  
  $BootstrapperUri = Get-MicrosoftTeamsBootstrapperUri

  Invoke-WebRequest -Uri $BootstrapperUri -OutFile $BootstrapperPath -UseBasicParsing -ErrorAction Stop

  if (-not (Test-Path -LiteralPath $BootstrapperPath -PathType Leaf)) {
    throw "The Microsoft Teams bootstrapper was not downloaded."
  }

  $BootstrapperFile = Get-Item -LiteralPath $BootstrapperPath -ErrorAction Stop

  if ($BootstrapperFile.Length -le 0) {
    throw "The downloaded Microsoft Teams bootstrapper is empty."
  }

  return $BootstrapperPath
}

function Test-MicrosoftTeamsBootstrapperSignature {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Path
  )

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    return [PSCustomObject]@{
      Valid   = $false
      Status  = "NotFound"
      Signer  = $null
      Message = "The Microsoft Teams bootstrapper was not found."
    }
  }

  try {
    $Signature = Get-AuthenticodeSignature -FilePath $Path -ErrorAction Stop

    $SignerSubject = if ($null -ne $Signature.SignerCertificate) {
      [string]$Signature.SignerCertificate.Subject
    }
    else {
      $null
    }

    $ValidMicrosoftSignature = ($Signature.Status -eq "Valid" -and $SignerSubject -match "Microsoft Corporation")

    return [PSCustomObject]@{
      Valid   = $ValidMicrosoftSignature
      Status  = [string]$Signature.Status
      Signer  = $SignerSubject
      Message = if ($ValidMicrosoftSignature) {
        "The Microsoft Teams bootstrapper signature is valid."
      }
      else {
        "The Microsoft Teams bootstrapper signature is not valid."
      }
    }
  }

  catch {
    return [PSCustomObject]@{
      Valid   = $false
      Status  = "Error"
      Signer  = $null
      Message = $_.Exception.Message
    }
  }
}

function Remove-MicrosoftTeamsBootstrapper {
  [CmdletBinding()]
  param()

  $BootstrapperDirectory = Get-MicrosoftTeamsBootstrapperDirectory

  if (Test-Path -LiteralPath $BootstrapperDirectory -PathType Container) {
    Remove-Item -LiteralPath $BootstrapperDirectory -Recurse -Force -ErrorAction SilentlyContinue
  }
}

function Test-MicrosoftTeamsDeploymentPackage {
  [CmdletBinding()]
  param()

  try {
    $BootstrapperPath = Save-MicrosoftTeamsBootstrapper
    $SignatureResult = Test-MicrosoftTeamsBootstrapperSignature -Path $BootstrapperPath
    $BootstrapperFile = Get-Item -LiteralPath $BootstrapperPath -ErrorAction Stop

    return [PSCustomObject]@{
      Valid     = [bool]$SignatureResult.Valid
      FileName  = $BootstrapperFile.Name
      FileSize  = $BootstrapperFile.Length
      Status    = $SignatureResult.Status
      Signer    = $SignatureResult.Signer
      Message   = $SignatureResult.Message
    }
  }

  catch {
    return [PSCustomObject]@{
      Valid     = $false
      FileName  = "teamsbootstrapper.exe"
      FileSize  = 0
      Status    = "Error"
      Signer    = $null
      Message   = $_.Exception.Message
    }
  }

  finally {
    Remove-MicrosoftTeamsBootstrapper
  }
}

# ============================================================
# MICROSOFT TEAMS INSTALLATION
# ============================================================

function Test-MicrosoftTeamsAdministrator {
  [CmdletBinding()]
  param()

  try {
    $CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)

    return $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  }

  catch {
    return $false
  }
}

function Write-MicrosoftTeamsDeploymentLog {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Message,
    [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR")]
    [string]$Level = "INFO"
  )

  $LoggingCommand = Get-Command -Name "Write-DeploymentLog" -ErrorAction SilentlyContinue

  if ($null -ne $LoggingCommand) {
    Write-DeploymentLog -Message $Message -Level $Level
  }
}

function Start-MicrosoftTeamsInstallation {
  [CmdletBinding(
    SupportsShouldProcess = $true,
    ConfirmImpact = "High"
  )]
  param()

  if (Test-MicrosoftTeamsInstalled) {
    $Message = "Microsoft Teams is already provisioned. Skipping."

    Write-MicrosoftTeamsDeploymentLog -Message $Message -Level "INFO"

    return [PSCustomObject]@{
      Status   = "Skipped"
      ExitCode = 0
      Message  = $Message
    }
  }

  $Target = "Microsoft Teams for all Windows users"
  $Action = "Provision Microsoft Teams"

  if (-not $PSCmdlet.ShouldProcess($Target, $Action)) {
    return [PSCustomObject]@{
      Status   = "Preview"
      ExitCode = $null
      Message  = "Microsoft Teams provisioning was previewed only."
    }
  }

  if (-not (Test-MicrosoftTeamsAdministrator)) {
    $Message = "Administrator permission is required to provision Microsoft Teams."

    Write-MicrosoftTeamsDeploymentLog -Message $Message -Level "ERROR"

    return [PSCustomObject]@{
      Status   = "Failed"
      ExitCode = $null
      Message  = $Message
    }
  }

  $BootstrapperPath = $null

  try {
    Write-Host
    Write-Host "Downloading the Microsoft Teams bootstrapper..." -ForegroundColor Cyan

    $BootstrapperPath = Save-MicrosoftTeamsBootstrapper
    $SignatureResult = Test-MicrosoftTeamsBootstrapperSignature -Path $BootstrapperPath

    if (-not $SignatureResult.Valid) {
      $Message = ("Microsoft Teams bootstrapper validation failed: {0}" -f $SignatureResult.Message)

      Write-MicrosoftTeamsDeploymentLog -Message $Message -Level "ERROR"

      return [PSCustomObject]@{
        Status   = "Failed"
        ExitCode = $null
        Message  = $Message
      }
    }

    Write-Host "Microsoft Teams bootstrapper signature is valid." -ForegroundColor Green

    Write-Host
    Write-Host "Provisioning Microsoft Teams..." -ForegroundColor Cyan

    Write-MicrosoftTeamsDeploymentLog -Message "Microsoft Teams provisioning started." -Level "INFO"

    $TeamsProcess = Start-Process -FilePath $BootstrapperPath -Wait -PassThru -NoNewWindow -ErrorAction Stop

    $ExitCode = [int]$TeamsProcess.ExitCode

    if ($ExitCode -ne 0) {
      $Message = ("Microsoft Teams provisioning failed with exit code {0}." -f $ExitCode)

      Write-MicrosoftTeamsDeploymentLog -Message $Message -Level "ERROR"

      return [PSCustomObject]@{
        Status   = "Failed"
        ExitCode = $ExitCode
        Message  = $Message
      }
    }

    $ProvisioningDetected = $false

    for ($Attempt = 1; $Attempt -le 12; $Attempt++) {
      if (Test-MicrosoftTeamsProvisioned) {
        $ProvisioningDetected = $true
        break
      }

      Start-Sleep -Seconds 5
    }

    if (-not $ProvisioningDetected) {
      $Message = @("The Microsoft Teams bootstrapper completed successfully,", "but the provisioned Teams package was not detected.") -join " "

      Write-MicrosoftTeamsDeploymentLog -Message $Message -Level "WARNING"

      return [PSCustomObject]@{
        Status   = "Failed"
        ExitCode = $ExitCode
        Message  = $Message
      }
    }

    $Message = "Microsoft Teams was provisioned successfully."

    Write-Host
    Write-Host $Message -ForegroundColor Green

    Write-MicrosoftTeamsDeploymentLog -Message $Message -Level "SUCCESS"

    return [PSCustomObject]@{
      Status   = "Installed"
      ExitCode = $ExitCode
      Message  = $Message
    }
  }

  catch {
    $Message = ("Microsoft Teams provisioning failed: {0}" -f $_.Exception.Message)

    Write-MicrosoftTeamsDeploymentLog -Message $Message -Level "ERROR"

    return [PSCustomObject]@{
      Status   = "Failed"
      ExitCode = $null
      Message  = $Message
    }
  }

  finally {
    Remove-MicrosoftTeamsBootstrapper
  }
}