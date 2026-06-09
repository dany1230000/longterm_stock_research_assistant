@echo off
setlocal

cd /d "%~dp0.."

for /f "usebackq delims=" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$ip = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -ne '127.0.0.1' -and $_.IPAddress -notlike '169.254*' -and $_.PrefixOrigin -ne 'WellKnown' } | Select-Object -First 1 -ExpandProperty IPAddress; if (-not $ip) { $ip = '127.0.0.1' }; Write-Output $ip"`) do set "LAN_IP=%%I"

if "%LAN_IP%"=="" set "LAN_IP=127.0.0.1"
if "%BACKEND_PORT%"=="" set "BACKEND_PORT=8000"
if "%FRONTEND_PORT%"=="" set "FRONTEND_PORT=8080"

echo 00631L LAN mobile info
echo Repo: %CD%
echo LAN IP: %LAN_IP%
echo.
echo Backend LAN URL:
echo   http://%LAN_IP%:%BACKEND_PORT%/health
echo.
echo Frontend LAN URL for phone:
echo   http://%LAN_IP%:%FRONTEND_PORT%/#/00631l-lab
echo.
echo Requirements:
echo   - Phone and PC must use the same Wi-Fi/LAN.
echo   - Backend must bind to 0.0.0.0.
echo   - Flutter web-server must bind to 0.0.0.0.
echo   - Windows Firewall may ask to allow Python and Flutter web-server.
echo.
exit /b 0
