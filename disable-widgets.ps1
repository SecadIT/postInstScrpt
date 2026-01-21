# Disable Windows Widgets completely via Group Policy
# This prevents the widgets feature from being available system-wide

# Check for admin privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrator privileges. Requesting elevation..." -ForegroundColor Yellow
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell.exe -ArgumentList $arguments -Verb RunAs -Wait
    exit
}

Write-Host "Disabling Windows Widgets via Group Policy..." -ForegroundColor Green

# Set the Group Policy to disable widgets
$policyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"

try {
    # Create the policy key if it doesn't exist
    if (-not (Test-Path $policyPath)) {
        New-Item -Path $policyPath -Force | Out-Null
        Write-Host "Created policy registry key." -ForegroundColor Yellow
    }
    
    # Set AllowNewsAndInterests to 0 (disabled)
    Set-ItemProperty -Path $policyPath -Name "AllowNewsAndInterests" -Value 0 -Type DWord
    Write-Host "Widgets disabled successfully via Group Policy." -ForegroundColor Green
    
    # Also disable in current user's taskbar settings
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0 -ErrorAction SilentlyContinue
    
    Write-Host ""
    Write-Host "Restarting Explorer to apply changes..." -ForegroundColor Yellow
    Stop-Process -Name explorer -Force
    Start-Sleep -Seconds 2
    Start-Process explorer.exe
    
    Write-Host ""
    Write-Host "Widgets have been completely disabled." -ForegroundColor Green
}
catch {
    Write-Host "Error disabling widgets: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")