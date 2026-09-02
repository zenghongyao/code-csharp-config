@echo off
rem Global agent rules uninstaller for Windows.
rem Usage: double-click, or use -Target Claude, Codex, or All.
rem Optional AGENT_CONFIG_HOME overrides the user directory for both targets.

chcp 65001 >nul
setlocal
set "SCRIPT_DIR=%~dp0"

if defined AGENT_CONFIG_HOME set "USERPROFILE=%AGENT_CONFIG_HOME%"

where pwsh >nul 2>&1
if %ERRORLEVEL% equ 0 (
    pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%uninstall.ps1" %*
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%uninstall.ps1" %*
)
set "EXIT_CODE=%ERRORLEVEL%"

echo.
pause
exit /b %EXIT_CODE%
