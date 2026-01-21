# Re-enable Windows Widgets by removing the Group Policy restriction

# Check for admin privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrator privileges. Requesting elevation..." -ForegroundColor Yellow
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell.exe -ArgumentList $arguments -Verb RunAs -Wait
    exit
}

Write-Host "Re-enabling Windows Widgets..." -ForegroundColor Green

# Remove the Group Policy restriction
$policyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"

if (Test-Path $policyPath) {
    try {
        Remove-ItemProperty -Path $policyPath -Name "AllowNewsAndInterests" -ErrorAction Stop
        Write-Host "Removed Group Policy restriction for widgets." -ForegroundColor Green
        
        # Optionally remove the entire key if it's empty
        $remainingValues = Get-ItemProperty -Path $policyPath
        if ($remainingValues.PSObject.Properties.Name.Count -eq 0) {
            Remove-Item -Path $policyPath -Force
            Write-Host "Removed empty policy key." -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Error removing policy: $_" -ForegroundColor Red
    }
}
else {
    Write-Host "No Group Policy restriction found. Widgets should already be available." -ForegroundColor Yellow
}

# Ensure the TaskbarDa value exists and set it to 1 (enabled)
$explorerPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
Set-ItemProperty -Path $explorerPath -Name "TaskbarDa" -Value 1 -Type DWord
Write-Host "Enabled widgets in taskbar settings." -ForegroundColor Green

# Restart Explorer to apply changes
Write-Host "Restarting Explorer to apply changes..." -ForegroundColor Yellow
Stop-Process -Name explorer -Force
Start-Sleep -Seconds 2
Start-Process explorer.exe

Write-Host ""
Write-Host "Widgets have been re-enabled. Check your taskbar." -ForegroundColor Green
Write-Host "Press any key to exit..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
