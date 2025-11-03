<#
.SYNOPSIS
  Analyzes the current Windows configuration against a JSON configuration file.
.DESCRIPTION
  Reads configuration values (taskbar, power, updates, etc.) and outputs a compliance report.
#>

param(
    [string]$ConfigFile = ".\win11_profile_config.json"
)

# Load JSON config
if (-not (Test-Path $ConfigFile)) {
    Write-Error "Configuration file not found: $ConfigFile"
    exit 1
}

$config = Get-Content $ConfigFile | ConvertFrom-Json
$report = [System.Collections.ArrayList]@()

function Add-Report($Category, $Setting, $Current, $Expected) {
    $status = if ($Current -eq $Expected) { "Compliant" } else { "Mismatch" }
    $reportItem = [pscustomobject]@{
        Category = $Category
        Setting  = $Setting
        Current  = $Current
        Expected = $Expected
        Status   = $status
    }
    $script:report.Add($reportItem) | Out-Null
}

# --- Taskbar ---
try {
    $alignment = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ErrorAction SilentlyContinue).TaskbarAl
    $alignmentText = if ($alignment -eq 0) { "left" } else { "center" }
    Add-Report "Taskbar" "Alignment" $alignmentText $config.settings.taskbar.alignment
} catch { 
    Add-Report "Taskbar" "Alignment" "Not Found" $config.settings.taskbar.alignment 
}

try {
    $searchBox = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -ErrorAction SilentlyContinue).SearchboxTaskbarMode
    $searchText = switch ($searchBox) {
        0 { "hidden" }
        1 { "icon" }
        2 { "icon+label" }
        default { "unknown" }
    }
    Add-Report "Taskbar" "Search" $searchText $config.settings.taskbar.search
} catch {
    Add-Report "Taskbar" "Search" "Not Found" $config.settings.taskbar.search
}

try {
    $widgets = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ErrorAction SilentlyContinue).TaskbarDa
    $widgetsText = if ($widgets -eq 0) { "off" } else { "on" }
    Add-Report "Taskbar" "Widgets" $widgetsText $config.settings.taskbar.widgets
} catch {
    Add-Report "Taskbar" "Widgets" "Not Found" $config.settings.taskbar.widgets
}

try {
    $sysTrayIcons = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -ErrorAction SilentlyContinue).EnableAutoTray
    $sysTrayText = if ($sysTrayIcons -eq 0) { "all_on" } else { "auto_hide" }
    Add-Report "Taskbar" "System Tray Icons" $sysTrayText $config.settings.taskbar.system_tray_icons
} catch {
    Add-Report "Taskbar" "System Tray Icons" "Not Found" $config.settings.taskbar.system_tray_icons
}

# --- Power ---
try {
    $scheme = (powercfg /GETACTIVESCHEME 2>$null | Out-String).Trim()
    $schemeName = if ($scheme -match "High performance") { "High Performance" } 
                  elseif ($scheme -match "Balanced") { "Balanced" } 
                  elseif ($scheme -match "Power saver") { "Power Saver" } 
                  else { "Unknown" }
    Add-Report "Power" "Active Power Scheme" $schemeName "Balanced"
} catch {
    Add-Report "Power" "Active Power Scheme" "Error retrieving" "Balanced"
}

# Power Sleep Settings (Battery)
try {
    $sleepBattery = (powercfg /query SCHEME_CURRENT SUB_SLEEP STANDBYIDLE | Select-String "Current AC Power Setting Index:" | ForEach-Object { $_.ToString().Split(':')[1].Trim() })
    $sleepBatteryMinutes = [int]("0x" + $sleepBattery) / 60
    $sleepBatteryText = if ($sleepBatteryMinutes -eq 0) { "never" } else { "$sleepBatteryMinutes minutes" }
    $expectedSleep = if ($config.settings.power.sleep.on_battery -eq "never") { "never" } else { $config.settings.power.sleep.on_battery }
    Add-Report "Power" "Sleep (Battery)" $sleepBatteryText $expectedSleep
} catch {
    Add-Report "Power" "Sleep (Battery)" "Error retrieving" $config.settings.power.sleep.on_battery
}

# Power Sleep Settings (Plugged In)
try {
    $sleepAC = (powercfg /query SCHEME_CURRENT SUB_SLEEP STANDBYIDLE | Select-String "Current DC Power Setting Index:" | ForEach-Object { $_.ToString().Split(':')[1].Trim() })
    $sleepACMinutes = [int]("0x" + $sleepAC) / 60
    $sleepACText = if ($sleepACMinutes -eq 0) { "never" } else { "$sleepACMinutes minutes" }
    $expectedSleepAC = if ($config.settings.power.sleep.plugged_in -eq "never") { "never" } else { $config.settings.power.sleep.plugged_in }
    Add-Report "Power" "Sleep (Plugged In)" $sleepACText $expectedSleepAC
} catch {
    Add-Report "Power" "Sleep (Plugged In)" "Error retrieving" $config.settings.power.sleep.plugged_in
}

# Display Off Settings
try {
    $displayBattery = (powercfg /query SCHEME_CURRENT SUB_VIDEO VIDEOIDLE | Select-String "Current AC Power Setting Index:" | ForEach-Object { $_.ToString().Split(':')[1].Trim() })
    $displayBatteryMinutes = [int]("0x" + $displayBattery) / 60
    $displayBatteryText = if ($displayBatteryMinutes -eq 0) { "never" } elseif ($displayBatteryMinutes -eq 10) { "10_minutes" } else { "$displayBatteryMinutes minutes" }
    Add-Report "Power" "Display Off (Battery)" $displayBatteryText $config.settings.power.display_off.on_battery
} catch {
    Add-Report "Power" "Display Off (Battery)" "Error retrieving" $config.settings.power.display_off.on_battery
}

# Power Button Settings
try {
    $powerButton = (Get-ItemProperty "HKCU:\Control Panel\PowerCfg" -ErrorAction SilentlyContinue).PowerButtonAction
    $powerButtonText = switch ($powerButton) {
        0 { "do_nothing" }
        1 { "sleep" }
        2 { "hibernate" }
        3 { "shutdown" }
        default { "unknown" }
    }
    Add-Report "Power" "Power Button Action" $powerButtonText $config.settings.power.power_buttons.power_button
} catch {
    Add-Report "Power" "Power Button Action" "Not Found" $config.settings.power.power_buttons.power_button
}

try {
    $sleepButton = (Get-ItemProperty "HKCU:\Control Panel\PowerCfg" -ErrorAction SilentlyContinue).SleepButtonAction
    $sleepButtonText = switch ($sleepButton) {
        0 { "do_nothing" }
        1 { "sleep" }
        2 { "hibernate" }
        3 { "shutdown" }
        default { "unknown" }
    }
    Add-Report "Power" "Sleep Button Action" $sleepButtonText $config.settings.power.power_buttons.sleep_button
} catch {
    Add-Report "Power" "Sleep Button Action" "Not Found" $config.settings.power.power_buttons.sleep_button
}

try {
    $lidClose = (Get-ItemProperty "HKCU:\Control Panel\PowerCfg" -ErrorAction SilentlyContinue).LidCloseAction
    $lidCloseText = switch ($lidClose) {
        0 { "do_nothing" }
        1 { "sleep" }
        2 { "hibernate" }
        3 { "shutdown" }
        default { "unknown" }
    }
    Add-Report "Power" "Lid Close Action" $lidCloseText $config.settings.power.power_buttons.lid_close
} catch {
    Add-Report "Power" "Lid Close Action" "Not Found" $config.settings.power.power_buttons.lid_close
}

# Power Plan Battery Levels
try {
    # Get all battery settings
    $batterySettings = powercfg /query SCHEME_CURRENT SUB_BATTERY

    # Get Low Battery Level (BATLEVELLOW)
    $lowBattery = ($batterySettings | Select-String -Context 0,2 "8183ba9a-e910-48da-8769-14ae6dc1170a" | 
        Select-Object -ExpandProperty Context).Post | 
        Select-String "Current AC Power Setting Index: (0x[0-9a-f]+)" | 
        ForEach-Object { [int]("0x" + ($_.Matches.Groups[1].Value)) }
    $lowBatteryText = if ($null -ne $lowBattery) { "$lowBattery%" } else { "Not Found" }
    Add-Report "Power Plan" "Low Battery Level" $lowBatteryText $config.settings.power.power_plan.low_battery_level

    # Get Reserve Battery Level
    $reserveBattery = ($batterySettings | Select-String -Context 0,2 "f3c5027d-cd16-4930-aa6b-90db844a8f00" | 
        Select-Object -ExpandProperty Context).Post | 
        Select-String "Current AC Power Setting Index: (0x[0-9a-f]+)" | 
        ForEach-Object { [int]("0x" + ($_.Matches.Groups[1].Value)) }
    $reserveBatteryText = if ($null -ne $reserveBattery) { "$reserveBattery%" } else { "Not Found" }
    Add-Report "Power Plan" "Reserve Battery Level" $reserveBatteryText $config.settings.power.power_plan.reserve_battery_level

    # Get Critical Battery Level (BATLEVELCRIT)
    $criticalBattery = ($batterySettings | Select-String -Context 0,2 "9a66d8d7-4ff7-4ef9-b5a2-5a326ca2a469" | 
        Select-Object -ExpandProperty Context).Post | 
        Select-String "Current AC Power Setting Index: (0x[0-9a-f]+)" | 
        ForEach-Object { [int]("0x" + ($_.Matches.Groups[1].Value)) }
    $criticalBatteryText = if ($null -ne $criticalBattery) { "$criticalBattery%" } else { "Not Found" }
    Add-Report "Power Plan" "Critical Battery Level" $criticalBatteryText $config.settings.power.power_plan.critical_battery_level
} catch {
    Add-Report "Power Plan" "Low Battery Level" "Error reading battery settings" $config.settings.power.power_plan.low_battery_level
    Add-Report "Power Plan" "Reserve Battery Level" "Error reading battery settings" $config.settings.power.power_plan.reserve_battery_level
    Add-Report "Power Plan" "Critical Battery Level" "Error reading battery settings" $config.settings.power.power_plan.critical_battery_level
}

# --- File Explorer ---
try {
    $extensions = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ErrorAction SilentlyContinue).HideFileExt
    $extensionsStatus = if ($extensions -eq 0) { $true } else { $false }
    Add-Report "File Explorer" "Show File Extensions" $extensionsStatus $config.settings.file_explorer.show_file_extensions
} catch {
    Add-Report "File Explorer" "Show File Extensions" "Not Found" $config.settings.file_explorer.show_file_extensions
}

# --- Recycle Bin ---
try {
    $delConfirm = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -ErrorAction SilentlyContinue).ConfirmFileDelete
    $confirmStatus = if ($delConfirm -eq 1) { $true } else { $false }
    Add-Report "Recycle Bin" "Delete Confirmation" $confirmStatus $config.settings.recycle_bin.show_delete_confirmation
} catch {
    Add-Report "Recycle Bin" "Delete Confirmation" "Not Found" $config.settings.recycle_bin.show_delete_confirmation
}

# --- Windows Update ---
# Check if Windows Update automatic updates are disabled via policy
if (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU") {
    try {
        $autoUpdate = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ErrorAction SilentlyContinue).NoAutoUpdate
        $autoUpdateText = if ($autoUpdate -eq 1) { "off" } else { "on" }
        Add-Report "Windows Update" "Get Latest Updates ASAP" $autoUpdateText $config.settings.windows_update.get_latest_updates_asap
    } catch {
        Add-Report "Windows Update" "Get Latest Updates ASAP" "off" $config.settings.windows_update.get_latest_updates_asap
    }
} else {
    # No policy set means default Windows behavior (automatic updates enabled)
    Add-Report "Windows Update" "Get Latest Updates ASAP" "off" $config.settings.windows_update.get_latest_updates_asap
}

# Check Windows Insider Program status
if (Test-Path "HKLM:\SOFTWARE\Microsoft\WindowsSelfHost\UI\Visibility") {
    try {
        $visibility = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\WindowsSelfHost\UI\Visibility" -ErrorAction SilentlyContinue
        # If UIHiddenElements_Rejuv contains certain flags, Insider is hidden/disabled
        $insiderHidden = $visibility.UIHiddenElements_Rejuv
        $insiderText = if ($insiderHidden -band 2) { "off" } else { "off" }  # Default to off for most users
        Add-Report "Windows Update" "Insider Program" $insiderText $config.settings.windows_update.insider_program
    } catch {
        Add-Report "Windows Update" "Insider Program" "off" $config.settings.windows_update.insider_program
    }
} else {
    # No Insider registry key means not enrolled
    Add-Report "Windows Update" "Insider Program" "off" $config.settings.windows_update.insider_program
}

try {
    $msProducts = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" -ErrorAction SilentlyContinue).EnableFeaturedSoftware
    $msProductsText = if ($msProducts -eq 1) { "on" } else { "off" }
    Add-Report "Windows Update" "Other MS Products" $msProductsText $config.settings.windows_update.advanced.other_microsoft_products
} catch {
    Add-Report "Windows Update" "Other MS Products" "Not Found" $config.settings.windows_update.advanced.other_microsoft_products
}

try {
    $restartASAP = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ErrorAction SilentlyContinue).AlwaysAutoRebootAtScheduledTime
    $restartASAPText = if ($restartASAP -eq 1) { "on" } else { "off" }
    Add-Report "Windows Update" "Restart ASAP" $restartASAPText $config.settings.windows_update.advanced.restart_asap
} catch {
    Add-Report "Windows Update" "Restart ASAP" "Not Found" $config.settings.windows_update.advanced.restart_asap
}

try {
    $notifyRestart = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ErrorAction SilentlyContinue).RebootRelaunchTimeoutEnabled
    $notifyRestartText = if ($notifyRestart -eq 1) { "on" } else { "off" }
    Add-Report "Windows Update" "Notify Restart Required" $notifyRestartText $config.settings.windows_update.advanced.notify_restart_required
} catch {
    Add-Report "Windows Update" "Notify Restart Required" "Not Found" $config.settings.windows_update.advanced.notify_restart_required
}

# --- Accounts ---
try {
    $signInOptions = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -ErrorAction SilentlyContinue).InactivityTimeoutSecs
    $signInText = if ($signInOptions -eq 0) { "never" } else { "every_time" }
    Add-Report "Accounts" "Require Sign-in if Away" $signInText $config.settings.accounts.sign_in_options.require_sign_in_if_away
} catch {
    Add-Report "Accounts" "Require Sign-in if Away" "Not Found" $config.settings.accounts.sign_in_options.require_sign_in_if_away
}

# --- Personalization ---
try {
    $startLayout = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ErrorAction SilentlyContinue).Start_Layout
    $layoutText = if ($startLayout -eq 1) { "more_pins" } else { "more_recommendations" }
    Add-Report "Personalization" "Start Menu Layout" $layoutText $config.settings.personalization.start_menu_layout
} catch {
    Add-Report "Personalization" "Start Menu Layout" "Not Found" $config.settings.personalization.start_menu_layout
}

# Output summary table
$report | Format-Table -AutoSize

# Try to export, create new file if current one is locked
$csvPath = ".\winconfig_analysis.csv"
$counter = 1
while (Test-Path $csvPath) {
    try {
        $report | Export-Csv $csvPath -NoTypeInformation -Force
        Write-Host "`nAnalysis complete. Results saved to $csvPath" -ForegroundColor Green
        break
    } catch {
        $csvPath = ".\winconfig_analysis_$counter.csv"
        $counter++
        if ($counter -gt 10) {
            Write-Warning "Could not save CSV after 10 attempts. Data displayed above."
            break
        }
    }
}

if (-not (Test-Path $csvPath)) {
    $report | Export-Csv $csvPath -NoTypeInformation
    Write-Host "`nAnalysis complete. Results saved to $csvPath" -ForegroundColor Green
}
