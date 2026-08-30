@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Doi-DNS.ps1"
if %errorlevel% neq 0 (
    echo.
    echo Co loi xay ra khi chay script.
    pause
)
endlocal