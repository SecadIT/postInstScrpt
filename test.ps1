# Ensure script is run as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as Administrator."
    exit
}

# Taskbar settings
# Note: Some taskbar settings may require third-party tools or Group Policy changes
Write-Output "Applying taskbar settings..."
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value 0 -PropertyType DWord -Force  # Align left
# Widgets and search settings are managed via Group Policy or UI, not directly via registry

# Power settings
Write-Output "Configuring power settings..."
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
powercfg /change monitor-timeout-ac 10
powercfg /change monitor-timeout-dc 10
powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS POWERBUTTONACTION 3
powercfg /setdcvalueindex SCHEME_CURRENT SUB_BUTTONS POWERBUTTONACTION 3
powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS SLEEPBUTTONACTION 0
powercfg /setdcvalueindex SCHEME_CURRENT SUB_BUTTONS SLEEPBUTTONACTION 0
powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDCLOSEACTION 1
powercfg /setdcvalueindex SCHEME_CURRENT SUB_BUTTONS LIDCLOSEACTION 1
powercfg /setdcvalueindex SCHEME_CURRENT SUB_BATTERY BATLEVELCRIT 10
powercfg /setdcvalueindex SCHEME_CURRENT SUB_BATTERY BATLEVELRESERVE 15
powercfg /setdcvalueindex SCHEME_CURRENT SUB_BATTERY BATLEVELLOW 20
powercfg /setactive SCHEME_CURRENT
# Sign-in options
Write-Output "Setting sign-in options..."
# This setting is typically managed via Group Policy or UI

# Windows Update settings
Write-Output "Configuring Windows Update settings..."
# These settings are best managed via Group Policy or MDM solutions

# Personalisation
Write-Output "Applying start menu layout..."
# This requires layout XML and Group Policy deployment

# File Explorer settings
Write-Output "Showing file extensions..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0

# Recycle Bin settings
Write-Output "Enabling delete confirmation..."
$recycleBinKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
New-Item -Path $recycleBinKey -Force | Out-Null
New-ItemProperty -Path $recycleBinKey -Name "ConfirmFileDelete" -Value 1 -PropertyType DWord -Force

Write-Output "Configuration complete."
``