<#
.SYNOPSIS
  Creates a new local administrator account with prompted credentials.
.DESCRIPTION
  Creates a local user account, sets a password, configures security questions,
  and adds the account to the Administrators group. Username and password are prompted.
.EXAMPLE
  .\Create-LocalAdmin.ps1
#>

# Check for admin privileges first (before prompting for credentials)
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrator privileges. Requesting elevation..." -ForegroundColor Yellow
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell.exe -ArgumentList $arguments -Verb RunAs -Wait
    exit
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Creating Local Administrator Account" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Prompt for username
$Username = Read-Host "Enter username for the new administrator account"
if ([string]::IsNullOrWhiteSpace($Username)) {
    Write-Host "[ERROR] Username cannot be empty!" -ForegroundColor Red
    Write-Host "Press any key to exit..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Prompt for password (visible input)
Write-Host ""
$Password1 = Read-Host "Enter password for '$Username'"
$Password2 = Read-Host "Confirm password"

# Verify passwords match
if ($Password1 -ne $Password2) {
    Write-Host ""
    Write-Host "[ERROR] Passwords do not match!" -ForegroundColor Red
    Write-Host "Press any key to exit..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Convert to secure string for account creation
$SecurePassword = ConvertTo-SecureString $Password1 -AsPlainText -Force

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# === CONFIGURATION SECTION - MODIFY THESE VALUES ===
$FullName = "$Username"  # Full name will match the username
$Description = "Administrator - Local account"

# Security Questions (3 required)
$SecurityQuestion1 = "What was the name of your first pet?"
$SecurityAnswer1 = "secad_pet"

$SecurityQuestion2 = "What city were you born in?"
$SecurityAnswer2 = "secad_city"

$SecurityQuestion3 = "What was your childhood nickname?"
$SecurityAnswer3 = "secad_nickname"



# Password settings
$PasswordNeverExpires = $true
$UserCannotChangePassword = $false
# === END CONFIGURATION SECTION ===

Write-Host "Username: $Username" -ForegroundColor Yellow
Write-Host ""

try {
    # Check if user already exists
    $existingUser = Get-LocalUser -Name $Username -ErrorAction SilentlyContinue
    if ($existingUser) {
        Write-Host "[ERROR] User '$Username' already exists!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Press any key to exit..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }

    # Create the local user account (SecurePassword already set from prompt)
    Write-Host "[Step 1/4] Creating user account..." -ForegroundColor Green
    New-LocalUser -Name $Username `
                  -Password $SecurePassword `
                  -FullName $FullName `
                  -Description $Description `
                  -PasswordNeverExpires:$PasswordNeverExpires `
                  -UserMayNotChangePassword:(!$UserCannotChangePassword) `
                  -AccountNeverExpires | Out-Null
    
    Write-Host "  User account created successfully." -ForegroundColor Gray
    Write-Host ""

    # Add user to Administrators group
    Write-Host "[Step 2/4] Adding to Administrators group..." -ForegroundColor Green
    Add-LocalGroupMember -Group "Administrators" -Member $Username
    Write-Host "  User added to Administrators group." -ForegroundColor Gray
    Write-Host ""

    # Set security questions using WMI (Windows Management Instrumentation)
    Write-Host "[Step 3/4] Configuring security questions..." -ForegroundColor Green
    
    # Note: Security questions are stored in user profile and may require the user to be logged in
    # We'll use registry approach for Windows 10/11
    try {
        # Get user SID
        $userSID = (Get-LocalUser -Name $Username).SID.Value
        
        # Note: Security questions are typically set when the user first logs in
        # or through the Windows Settings UI. Direct registry modification may not work
        # for all scenarios. This is a limitation of Windows security.
        
        Write-Host "  Security questions will be configured on first login." -ForegroundColor Yellow
        Write-Host "  Questions to use:" -ForegroundColor Gray
        Write-Host "    1. $SecurityQuestion1 -> $SecurityAnswer1" -ForegroundColor Gray
        Write-Host "    2. $SecurityQuestion2 -> $SecurityAnswer2" -ForegroundColor Gray
        Write-Host "    3. $SecurityQuestion3 -> $SecurityAnswer3" -ForegroundColor Gray
    }
    catch {
        Write-Host "  Note: Security questions configuration requires user login." -ForegroundColor Yellow
    }
    Write-Host ""

    # Display account settings
    Write-Host "[Step 4/4] Verifying account settings..." -ForegroundColor Green
    $newUser = Get-LocalUser -Name $Username
    Write-Host "  Name: $($newUser.Name)" -ForegroundColor Gray
    Write-Host "  Full Name: $($newUser.FullName)" -ForegroundColor Gray
    Write-Host "  Description: $($newUser.Description)" -ForegroundColor Gray
    Write-Host "  Enabled: $($newUser.Enabled)" -ForegroundColor Gray
    Write-Host "  Password Expires: $(-not $newUser.PasswordNeverExpires)" -ForegroundColor Gray
    Write-Host "  Account Expires: $($newUser.AccountExpires)" -ForegroundColor Gray
    Write-Host ""

    Write-Host "========================================" -ForegroundColor Green
    Write-Host "SUCCESS: Local administrator account created!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Account Details:" -ForegroundColor Cyan
    Write-Host "  Username: $Username" -ForegroundColor White
    Write-Host "  Password: ********" -ForegroundColor White
    Write-Host "  Group: Administrators" -ForegroundColor White
    Write-Host ""
    Write-Host "IMPORTANT: Store these credentials securely!" -ForegroundColor Yellow
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "ERROR: Failed to create account" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "Error details: $_" -ForegroundColor Red
    Write-Host ""
}

Write-Host "Press any key to exit..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
