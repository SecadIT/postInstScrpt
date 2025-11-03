<#
.SYNOPSIS
  Applies Windows configuration from a JSON file.
.DESCRIPTION
  Updates system and user settings such as taskbar alignment, file explorer options, and power behavior.
#>

param(
    [string]$ConfigFile = ".\win11_profile_config.json"
)

if (-not (Test-Path $ConfigFile)) {
    Write-Error "Configuration file not found: $ConfigFile"
    exit 1
}

$config = Get-Content $ConfigFile | ConvertFrom-Json

# --- Taskbar Alignment ---
if ($config.settings.taskbar.alignment -eq "left") {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value 0
    Write-Host "Taskbar alignment set to left."
}

# --- File Explorer: Show File Extensions ---
if ($config.settings.file_explorer.show_file_extensions -eq $true) {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
    Write-Host "File extensions are now visible."
}

# --- Recycle Bin: Delete Confirmation ---
if ($config.settings.recycle_bin.show_delete_confirmation -eq $true) {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "ConfirmFileDelete" -Value 1
    Write-Host "Recycle Bin delete confirmation enabled."
}

# --- Power Options Example (partial) ---
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
powercfg /change monitor-timeout-ac 10
powercfg /change monitor-timeout-dc 10

Write-Host "`nConfiguration applied successfully. Some changes may require restart or re-logon." -ForegroundColor Green
