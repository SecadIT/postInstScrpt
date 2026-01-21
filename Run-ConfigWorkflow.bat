@echo off
echo ========================================
echo Windows 11 Configuration Orchestrator
echo ========================================
echo.

:: Check current execution policy
echo [Step 1/5] Checking PowerShell Execution Policy...
powershell -command "$policy = Get-ExecutionPolicy -Scope CurrentUser; Write-Host 'Current Policy: ' -NoNewline; Write-Host $policy -ForegroundColor Cyan; if ($policy -eq 'Restricted' -or $policy -eq 'AllSigned' -or $policy -eq 'Undefined') { exit 1 } else { exit 0 }"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [WARNING] Execution policy is restricted. Setting to Unrestricted...
    echo.
    call PwrShell-UnRestrictScript-Test.bat
    timeout /t 3 /nobreak >nul
    echo.
    echo Execution policy updated. Continuing...
    echo.
) else (
    echo [OK] Execution policy allows script execution.
    echo.
)

:: Run initial analysis
echo [Step 2/5] Running Initial Configuration Analysis (BEFORE)...
echo ========================================
echo.
powershell -ExecutionPolicy Bypass -File ".\analyze-winconfig.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Analysis failed. Check the script and try again.
    pause
    exit /b 1
)

echo.
echo ========================================
echo [Step 3/5] Applying Configuration Settings...
echo ========================================
echo.
echo This will require administrator privileges.
echo Press any key to continue or Ctrl+C to cancel...
pause >nul
echo.

powershell -ExecutionPolicy Bypass -File ".\apply_settings.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [WARNING] Settings application may have encountered issues.
    echo.
)

:: Wait a moment for settings to take effect
echo.
echo [Step 4/5] Waiting for settings to take effect...
timeout /t 5 /nobreak >nul
echo.

:: Run final analysis
echo [Step 5/5] Running Final Configuration Analysis (AFTER)...
echo ========================================
echo.
powershell -ExecutionPolicy Bypass -File ".\analyze-winconfig.ps1"

echo.
echo ========================================
echo Configuration Workflow Complete!
echo ========================================
echo.
echo Review the analysis results above to verify compliance.
echo.
pause
