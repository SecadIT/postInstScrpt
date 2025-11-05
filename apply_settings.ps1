# Ensure the script runs with elevated privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrator privileges. Requesting elevation..." -ForegroundColor Yellow
    
    # Re-launch the script with elevated privileges
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell.exe -ArgumentList $arguments -Verb RunAs -Wait
    exit
}

Write-Host "Running with administrator privileges..." -ForegroundColor Green
Write-Host ""

# Logging function
# function Log-Setting {
#     param(
#         [string]$Setting,
#         [string]$Status
#     )
#     Add-Content -Path "settings-applied.log" -Value "$Setting,$Status"
# }

# Taskbar Alignment: Left
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value 0
Write-Host "Taskbar alignment set to left."

# Restart Explorer to apply taskbar changes
Stop-Process -Name explorer -Force
Start-Sleep -Seconds 2
Start-Process explorer.exe

# Taskbar Settings
# Search: icon + label
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 2

# Widgets: Off
#Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0

# System Tray Icons: Show all icons in taskbar
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "EnableAutoTray" -Value 0

# Turn ON all individual system tray icons (set IsPromoted=1 for all)
Get-ChildItem -Path "HKCU:\Control Panel\NotifyIconSettings" -ErrorAction SilentlyContinue | ForEach-Object {
    Set-ItemProperty -Path $_.PSPath -Name "IsPromoted" -Value 1 -ErrorAction SilentlyContinue
}
Write-Host "All system tray icons set to visible in taskbar."

# Power Settings
# Set active power plan to Balanced
powercfg /setactive SCHEME_BALANCED
Write-Host "Active power plan set to Balanced."

powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
powercfg /change monitor-timeout-ac 10
powercfg /change monitor-timeout-dc 10
Write-Host "Sleep timeout set to 'never' for both AC and battery."
Write-Host "Display off timeout set to 10 minutes for both AC and battery."


# Power Button Action: shutdown (3)
powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS 7648efa3-dd9c-4e3e-b566-50f929386280 3
powercfg /setdcvalueindex SCHEME_CURRENT SUB_BUTTONS 7648efa3-dd9c-4e3e-b566-50f929386280 3

# Sleep Button Action: do_nothing (0)
powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS 96996bc0-ad50-47ec-923b-6f41874dd9eb 0
powercfg /setdcvalueindex SCHEME_CURRENT SUB_BUTTONS 96996bc0-ad50-47ec-923b-6f41874dd9eb 0

# Lid Close Action: hibernate (2)
powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS 5ca83367-6e45-459f-a27b-476b1d01c936 2
powercfg /setdcvalueindex SCHEME_CURRENT SUB_BUTTONS 5ca83367-6e45-459f-a27b-476b1d01c936 2

# Activate the current scheme
powercfg /setactive SCHEME_CURRENT

Write-Host "Power button, sleep button, and lid close actions have been set."

# Battery Levels and Actions
# Critical battery level: 10%
powercfg /setdcvalueindex SCHEME_CURRENT SUB_BATTERY BATLEVELCRIT 10
powercfg /setacvalueindex SCHEME_CURRENT SUB_BATTERY BATLEVELCRIT 10

# Low battery level: 20%
powercfg /setdcvalueindex SCHEME_CURRENT SUB_BATTERY BATLEVELLOW 20
powercfg /setacvalueindex SCHEME_CURRENT SUB_BATTERY BATLEVELLOW 20

# Reserve battery level: 15%
powercfg /setdcvalueindex SCHEME_CURRENT SUB_BATTERY f3c5027d-cd16-4930-aa6b-90db844a8f00 15
powercfg /setacvalueindex SCHEME_CURRENT SUB_BATTERY f3c5027d-cd16-4930-aa6b-90db844a8f00 15

# Critical battery action: Hibernate (2)
powercfg /setdcvalueindex SCHEME_CURRENT SUB_BATTERY BATACTIONCRIT 2
powercfg /setacvalueindex SCHEME_CURRENT SUB_BATTERY BATACTIONCRIT 2

# Low battery action: Do nothing (0)
powercfg /setdcvalueindex SCHEME_CURRENT SUB_BATTERY BATACTIONLOW 0
powercfg /setacvalueindex SCHEME_CURRENT SUB_BATTERY BATACTIONLOW 0

# Low battery notification: On (1)
powercfg /setdcvalueindex SCHEME_CURRENT SUB_BATTERY BATFLAGSLOW 1
powercfg /setacvalueindex SCHEME_CURRENT SUB_BATTERY BATFLAGSLOW 1

# Critical battery notification: On (1)
powercfg /setdcvalueindex SCHEME_CURRENT SUB_BATTERY BATFLAGSCRIT 1
powercfg /setacvalueindex SCHEME_CURRENT SUB_BATTERY BATFLAGSCRIT 1

Write-Host "Battery levels and actions configured."

# Personalization: Start Menu Layout
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_Layout" -Value 1

# File Explorer: Show file extensions
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
Stop-Process -Name explorer -Force
Start-Sleep -Seconds 2
Start-Process explorer.exe

# Accounts: Require sign-in if away
if (-not (Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System")) {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies" -Name "System" -Force | Out-Null
}
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "InactivityTimeoutSecs" -Value 0
Write-Host "Sign-in required if away setting applied."

# Windows Update Settings
# Turn OFF "Get the latest updates as soon as they're available"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "IsContinuousInnovationOptedIn" -Value 0

# Enable updates for other Microsoft products
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "AllowMUUpdateService" -Value 1

# Enable restart notifications
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "RestartNotificationsAllowed2" -Value 1

# Turn OFF "Restart this device as soon as possible" (via Group Policy)
if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU")) {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "AU" -Force | Out-Null
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -Value 1

Write-Host "Windows Update: Receive updates for other Microsoft products enabled."
Write-Host "Windows Update: Restart notifications enabled."
Write-Host "Windows Update: Auto-restart with logged on users disabled."

# Recycle Bin: Show delete confirmation
if (-not (Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer")) {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies" -Name "Explorer" -Force | Out-Null
}
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "ConfirmFileDelete" -Value 1
Write-Host "Recycle Bin delete confirmation enabled."

Write-Host "Settings applied successfully. Please restart your computer for all changes to take effect."
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Green
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")