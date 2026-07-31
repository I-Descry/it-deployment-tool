# ============================================================
# LOCAL USER CONFIGURATION
# ============================================================

function Test-DeploymentLocalUserName {
  param(
    [Parameter(Mandatory)]
    [string]$UserName
  )

  $NormalizedUserName = $UserName.Trim()

  if ([string]::IsNullOrWhiteSpace($NormalizedUserName)) {
    return [PSCustomObject]@{
      Valid    = $false
      UserName = $NormalizedUserName
      Message  = "The username cannot be empty."
    }
  }

  if ($NormalizedUserName.Length -gt 20) {
    return [PSCustomObject]@{
      Valid    = $false
      UserName = $NormalizedUserName
      Message  = "The username cannot exceed 20 characters."
    }
  }

  if ($NormalizedUserName -notmatch "^[A-Za-z0-9._-]+$") {
    return [PSCustomObject]@{
      Valid    = $false
      Username = $NormalizedUserName
      Message  = ("Use only letters, numbers, periods, " + "uderscores, and hyphens.")
    }
  }

  $ReservedUserNames = @("Administrator", "DefaultAccount", "Guest", "WDAGUtilityAccount")

  if ($ReservedUserNames -contains $NormalizedUserName) {
    return [PSCustomObject]@{
      Valid    = $false
      UserName = $NormalizedUserName
      Message  = "This username is reserved by Windows."
    }
  }

  return [PSCustomObject]@{
    Valid    = $true
    UserName = $NormalizedUserName
    Message  = "The username is valid."
  }
}

function Test-LocalUserExists {
  param(
    [Parameter(Mandatory)]
    [string]$UserName
  )

  $ExistingUser = Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue

  return ($null -ne $ExistingUser)
}

function Test-SecurePasswordMatch {
  param(
    [Parameter(Mandatory)]
    [Security.SecureString]$Password,

    [Parameter(Mandatory)]
    [Security.SecureString]$Confirmation
  )

  $PasswordPointer = [IntPtr]::Zero
  $ConfirmationPointer = [IntPtr]::Zero

  try {
    $PasswordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    $ConfirmationPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Confirmation)
    $PasswordText = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($PasswordPointer)
    $ConfirmationText = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ConfirmationPointer)

    return ($PasswordText -ceq $ConfirmationText)
  }

  finally {
    if ($PasswordPointer -ne [IntPtr]::Zero) {
      [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($PasswordPointer)
    }

    if ($ConfirmationPointer -ne [IntPtr]::Zero) {
      [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ConfirmationPointer)
    }

    $PasswordText = $null
    $ConfirmationText = $null
  }
}

function New-DeploymentLocalStandardUser {
  [CmdletBinding(
    SupportsShouldProcess = $true,
    ConfirmImpact = "High"
  )]
  param(
    [Parameter(Mandatory)]
    [string]$UserName,

    [Parameter(Mandatory)]
    [Security.SecureString]$Password,

    [string]$FullName
  )

  try {
    $Validation = Test-DeploymentLocalUserName -UserName $UserName

    if (-not $Validation.Valid) {
      return [PSCustomObject]@{
        Status   = "Failed"
        UserName = $Validation.UserName
        Message  = $Validation.Message
      }
    }

    $NormalizedUserName = $Validation.UserName

    if (Test-LocalUserExists -UserName $NormalizedUserName) {
      return [PSCustomObject]@{
        Status   = "Skipped"
        UserName = $NormalizedUserName
        Message  = "The local user already exists."
      }
    }

    if ((-not $WhatIfPreference) -and (-not (Test-CurrentProcessAdministrator))) {
      return [PSCustomObject]@{
        Status   = "Failed"
        UserName = $NormalizedUserName
        Message  = ("Administrator permission is required " + "to create a local user.")
      }
    }

    if (-not $PSCmdlet.ShouldProcess($NormalizedUserName, "Create local standard user")) {
      return [PSCustomObject]@{
        Status   = "Preview Only"
        UserName = $NormalizedUserName
        Message  = "The local user was not created."
      }
    }

    $NewUserParameters = @{
      Name        = $NormalizedUserName
      Password    = $Password
      Description = "Created by IT Deployment Tool"
      ErrorAction = "Stop"
    }

    if (-not [string]::IsNullOrWhiteSpace($Fullname)) {
      $NewUserParameters.FullName = $FullName.Trim()
    }

    $CreatedUser = New-LocalUser @NewUserParameters

    try {
      $LocalGroups = @(Get-LocalGroup -ErrorAction Stop)
      $UsersGroup = $LocalGroups | Where-Object {
        ([string]$_.SID.Value) -eq "S-1-5-32-545"
      } | Select-Object -First 1

      if ($null -eq $UsersGroup) {
        throw "The built-in Users group could not be found."
      }

      $AdministratorsGroup = $LocalGroups | Where-Object {
        ([string]$_.SID.Value) -eq "S-1-5-32-544"
      } | Select-Object -First 1

      if ($null -eq $AdministratorsGroup) {
        throw "The built-in Administrators group could not be found."
      }

      $UsersMembership = @(Get-LocalGroupMember -Group $UsersGroup.Name -ErrorAction Stop | Where-Object {
        ([string]$_.SID.Value) -eq ([string]$CreatedUser.SID.Value)
      })

      if ($UsersMembership.Count -eq 0) {
        Add-LocalGroupMember -Group $UsersGroup.Name -Member $CreatedUser -ErrorAction Stop
      }

      $AdministratorMembership = @(Get-LocalGroupMember -Group $AdministratorsGroup.Name -ErrorAction Stop | Where-Object {
        ([string]$_.SID.Value) -eq ([string]$CreatedUser.SID.Value)
      })

      if ($AdministratorMembership.Count -gt 0) {
        Remove-LocalGroupMember -Group $AdministratorsGroup.Name -Member $CreatedUser -ErrorAction Stop
      }
    }

    catch {
      Remove-LocalUser -Name $CreatedUser.Name -ErrorAction SilentlyContinue

      throw ("The user account could not be configured " + "as a standard user. The account was removed. " + $_.Exception.Message)
    }

    $LoggingCommand = Get-Command -Name "Write-DeploymentLog" -ErrorAction SilentlyContinue

    if ($null -ne $LoggingCommand) {
      Write-DeploymentLog -Message ("Created local standard user: {0}" -f $NormalizedUserName) -Level "INFO"
    }

    return [PSCustomObject]@{
      Status   = "Created"
      UserName = $NormalizedUserName
      Message  = "The local standard user was created successfully."
    }
  }

  catch {
    return [PSCustomObject]@{
      Status   = "Failed"
      UserName = $UserName
      Message  = $_.Exception.Message
    }
  }
}

function Start-LocalStandardUserWizard {
  Clear-Host

  Write-Title -Title "CREATE LOCAL STANDARD USER"
  Write-Section -Title "Account Requirements"

  Write-Host " Maximum username length : 20 characters"
  Write-Host " Allowed characters      : Letters, numbers, . _ -"
  Write-Host " Account type            : Standard User"
  Write-Host " Password storage        : Not stored or logged"

  Write-Host

  $RequestedUserName = Read-Host "Enter the username or press ENTER to cancel"

  if ([string]::IsNullOrWhiteSpace($RequestedUserName)) {
    Write-Host
    Write-Host "Local user creation cancelled." -ForegroundColor Yellow

    Pause-Application
    return
  }

  $Validation = Test-DeploymentLocalUserName -UserName $RequestedUserName

  if (-not $Validation.Valid) {
    Write-Host
    Write-Host $Validation.Message -ForegroundColor Red

    Pause-Application
    return
  }

  $UserName = $Validation.UserName

  if (Test-LocalUserExists -UserName $UserName) {
    Write-Host
    Write-Host "The local user already exists." -ForegroundColor Yellow

    Pause-Application
    return
  }

  $FullName = Read-Host "Enter the user's full name or press ENTER to skip"

  Write-Host

  $Password = Read-Host "Enter the password" -AsSecureString

  $PasswordConfirmation = Read-Host "Confirm the password" -AsSecureString

  if (-not (Test-SecurePasswordMatch -Password $Password -Confirmation $PasswordConfirmation)) {
    Write-Host
    Write-Host "The passwords do not match." -ForegroundColor Red

    Pause-Application
    return
  }

  Write-Section -Title "Account Preview"
  Write-Info -Name "Username" -Value $UserName

  if (-not [string]::IsNullOrWhiteSpace($FullName)) {
    Write-Info -Name "Full Name" -Value $FullName
  }

  Write-Info -Name "Account Type" -Value "Standard User"

  Write-Host

  $Confirmation = Read-Host "Create this local user? (Y/N)"

  if ($Confirmation.Trim().ToUpper() -ne "Y") {
    Write-Host
    Write-Host "Local user creation cancelled." -ForegroundColor Yellow

    Pause-Application
    return
  }

  $CreationResult = New-DeploymentLocalStandardUser -UserName $UserName -Password $Password -FullName $FullName -Confirm:$false

  Write-Host

  switch ($CreationResult.Status) {
    "Created" {
      Write-Host -Object $CreationResult.Message -ForegroundColor Green
    }

    "Skipped" {
      Write-Host -Object $CreationResult.Message -ForegroundColor Yellow
    }

    default {
      Write-Host -Object $CreationResult.Message -ForegroundColor Red
    }
  }

  $Password = $null
  $PasswordConfirmation = $null

  Pause-Application
}