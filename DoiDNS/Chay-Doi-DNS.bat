@echo off
title DNS Manager Pro - TQN
cd /d "%~dp0"

:: Auto-elevate to Administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process '%~0' -Verb RunAs"
    exit /b
)

:: Run PowerShell script hidden
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0Doi-DNS.ps1"
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Cannot start DNS Manager Pro.
    pause
)