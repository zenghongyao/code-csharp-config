@echo off
rem One-click install Claude Code global config (Windows)
rem Usage: double-click install.bat, or pass args like -WhatIf
rem Optional env var: CLAUDE_HOME (override default %USERPROFILE%)
rem Design: -ExecutionPolicy Bypass to skip policy prompt, pause to keep window open

chcp 65001 >nul

setlocal
set "SCRIPT_DIR=%~dp0"

if defined CLAUDE_HOME (
    set "USERPROFILE=%CLAUDE_HOME%"
)

where pwsh >nul 2>&1
if %ERRORLEVEL% equ 0 (
    pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%install.ps1" %*
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%install.ps1" %*
)

echo.
pause