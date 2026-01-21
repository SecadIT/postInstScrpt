@echo off

:: direct pwsh cmcd to: get system info
powershell -command "get-ciminstance -classname win32_bios"

:: direct pwsh cmcd to: check execution policy
powershell -command "get-executionpolicy -list"



:: pwsh sub-shell to: check execution policy
powershell -command "start-process powershell -verb runas -argumentlist '-noexit', '-executionpolicy', 'bypass', 'get-executionpolicy -list'"

:: pwsh sub-shell to: derestrict currentuser's execution policy
:: powershell -command "start-process powershell -verb runas -argumentlist '-noexit', '-executionpolicy', 'bypass', 'set-executionpolicy -scope currentuser unrestricted'"

:: pwsh sub-shell to: check execution policy
:: powershell -command "start-process powershell -verb runas -argumentlist '-noexit', '-executionpolicy', 'bypass', 'get-executionpolicy -list'"

pause
