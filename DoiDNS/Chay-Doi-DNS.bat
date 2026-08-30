@echo off
setlocal
cd /d "%~dp0"

:: Kiem tra task Scheduler de khoi chay truc tiep voi quyen Admin ma khong can hoi UAC
schtasks /query /tn "DNSManagerPro_Elevated" >nul 2>&1
if %errorlevel% equ 0 (
    schtasks /run /tn "DNSManagerPro_Elevated" >nul 2>&1
    exit /b 0
)

:: Neu chua dang ky (chay lan dau tien), khoi dong de xin quyen Admin 1 lan duy nhat va tu dong tao Task
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Doi-DNS.ps1"
if %errorlevel% neq 0 (
    echo.
    echo Co loi xay ra khi khoi chay ung dung.
    pause
)
endlocal