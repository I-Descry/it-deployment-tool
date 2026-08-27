# ============================================================
# LOCAL USER CONFIGURATION
# ============================================================

function Test-DeploymentLocalUserName {
  param(
    # AllowEmptyString so a genuinely empty username field falls through to
    # the friendly "cannot be empty" message below, rather than PowerShell's
    # own mandatory-parameter binder rejecting the empty string outright
    # (which would throw before this function's body ever runs).
    [Parameter(Mandatory)]
    [AllowEmptyString()]
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
      UserName = $NormalizedUserName
      Message  = ("Use only letters, numbers, periods, " + "underscores, and hyphens.")
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

function Get-DeploymentLocalStandardUsers {
  [CmdletBinding()]
  param()

  try {
    $ReservedUserNames = @("Administrator", "DefaultAccount", "Guest", "WDAGUtilityAccount")

    $LocalGroups = @(Get-LocalGroup -ErrorAction Stop)

    $AdministratorsGroup = $LocalGroups | Where-Object {
      ([string]$_.SID.Value) -eq "S-1-5-32-544"
    } | Select-Object -First 1

    if ($null -eq $AdministratorsGroup) {
      return @()
    }

    $AdministratorMemberSids = @(Get-LocalGroupMember -Group $AdministratorsGroup.Name -ErrorAction Stop | Foreach-Object {
      [string]$_.SID.Value
    })

    $DeploymentUsers = @(Get-LocalUser -ErrorAction Stop | Where-Object {
      $UserSid = [string]$_.SID.Value

      $_.Enabled -and
      $_.Description -eq "Created by IT Deployment Tool" -and $ReservedUserNames -notcontains $_.Name -and $AdministratorMemberSids -notcontains $UserSid
    } | Select-Object Name, FullName, Enabled, Description, SID)

    return $DeploymentUsers
  }

  catch {
    return @()
  }
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

    [Security.SecureString]$Password,

    # An explicit opt-in for creating the account with a blank password via
    # New-LocalUser's own -NoPassword parameter. Never implied by simply
    # leaving $Password unset, so a caller can't create a passwordless
    # account by accident.
    [switch]$NoPassword,

    [string]$FullName
  )

  try {
    $LoggingCommand = Get-Command -Name "Write-DeploymentLog" -ErrorAction SilentlyContinue

    $Validation = Test-DeploymentLocalUserName -UserName $UserName

    if (-not $Validation.Valid) {
      if ($null -ne $LoggingCommand) {
        Write-DeploymentLog -Message ("Local standard user creation failed: {0}" -f $Validation.Message) -Level "WARNING"
      }

      return [PSCustomObject]@{
        Status   = "Failed"
        UserName = $Validation.UserName
        Message  = $Validation.Message
      }
    }

    if ((-not $NoPassword) -and (($null -eq $Password) -or ($Password.Length -eq 0))) {
      return [PSCustomObject]@{
        Status   = "Failed"
        UserName = $Validation.UserName
        Message  = "A password is required unless creating the account without one."
      }
    }

    $NormalizedUserName = $Validation.UserName

    if (Test-LocalUserExists -UserName $NormalizedUserName) {
      if ($null -ne $LoggingCommand) {
        Write-DeploymentLog -Message ("Local standard user creation skipped: {0} already exists." -f $NormalizedUserName) -Level "INFO"
      }

      return [PSCustomObject]@{
        Status   = "Skipped"
        UserName = $NormalizedUserName
        Message  = "The local user already exists."
      }
    }

    if ((-not $WhatIfPreference) -and (-not (Test-CurrentProcessAdministrator))) {
      if ($null -ne $LoggingCommand) {
        Write-DeploymentLog -Message ("Local standard user creation failed: administrator permission is required.") -Level "ERROR"
      }

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
      Description = "Created by IT Deployment Tool"
      ErrorAction = "Stop"
    }

    if ($NoPassword) {
      $NewUserParameters.NoPassword = $true
    }
    else {
      $NewUserParameters.Password = $Password
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

    if ($null -ne $LoggingCommand) {
      $LogPasswordNote = if ($NoPassword) { "Created without a password." } else { "" }
      Write-DeploymentLog -Message ("Created local standard user: {0}. {1}" -f $NormalizedUserName, $LogPasswordNote).Trim() -Level "INFO"
    }

    $CreatedMessage = if ($NoPassword) {
      "The local standard user was created successfully without a password. " +
      "By default Windows only allows a blank-password local account to sign in at the console, not over the network (RDP, file sharing, etc.)."
    }
    else {
      "The local standard user was created successfully."
    }

    return [PSCustomObject]@{
      Status   = "Created"
      UserName = $NormalizedUserName
      Message  = $CreatedMessage
    }
  }

  catch {
    $LoggingCommand = Get-Command -Name "Write-DeploymentLog" -ErrorAction SilentlyContinue

    if ($null -ne $LoggingCommand) {
      Write-DeploymentLog -Message ("Local standard user creation failed: {0}" -f $_.Exception.Message) -Level "ERROR"
    }

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

  $Password = Read-Host "Enter the password, or press ENTER to create the account with no password" -AsSecureString
  $NoPasswordChosen = ($Password.Length -eq 0)

  if (-not $NoPasswordChosen) {
    $PasswordConfirmation = Read-Host "Confirm the password" -AsSecureString

    if (-not (Test-SecurePasswordMatch -Password $Password -Confirmation $PasswordConfirmation)) {
      Write-Host
      Write-Host "The passwords do not match." -ForegroundColor Red

      Pause-Application
      return
    }
  }

  Write-Section -Title "Account Preview"
  Write-Info -Name "Username" -Value $UserName

  if (-not [string]::IsNullOrWhiteSpace($FullName)) {
    Write-Info -Name "Full Name" -Value $FullName
  }

  Write-Info -Name "Account Type" -Value "Standard User"
  Write-Info -Name "Password" -Value $(if ($NoPasswordChosen) { "None" } else { "Set" })

  if ($NoPasswordChosen) {
    Write-Host
    Write-Host "By default Windows only allows a blank-password local account to sign in at the console, not over the network (RDP, file sharing, etc.)." -ForegroundColor Yellow
  }

  Write-Host

  $Confirmation = Read-Host "Create this local user? (Y/N)"

  if ($Confirmation.Trim().ToUpper() -ne "Y") {
    Write-Host
    Write-Host "Local user creation cancelled." -ForegroundColor Yellow

    Pause-Application
    return
  }

  $CreationResult = New-DeploymentLocalStandardUser -UserName $UserName -Password $Password -NoPassword:$NoPasswordChosen -FullName $FullName -Confirm:$false

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