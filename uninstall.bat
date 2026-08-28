@echo off
rem One-click uninstall Claude Code global config (Windows)
rem Usage: double-click uninstall.bat, or pass args like -Purge
rem Optional env var: CLAUDE_HOME (override default %USERPROFILE%, mirrors install.bat)
rem Design: -ExecutionPolicy Bypass to skip policy prompt, pause to keep window open

chcp 65001 >nul

setlocal
set "SCRIPT_DIR=%~dp0"

if defined CLAUDE_HOME (
    set "USERPROFILE=%CLAUDE_HOME%"
)

where pwsh >nul 2>&1
if %ERRORLEVEL% equ 0 (
    pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%uninstall.ps1" %*
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%uninstall.ps1" %*
)

echo.
pause