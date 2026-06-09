@echo off
setlocal

cd /d "%~dp0.."

for /f "usebackq delims=" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$ip = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -ne '127.0.0.1' -and $_.IPAddress -notlike '169.254*' -and $_.PrefixOrigin -ne 'WellKnown' } | Select-Object -First 1 -ExpandProperty IPAddress; if (-not $ip) { $ip = '127.0.0.1' }; Write-Output $ip"`) do set "LAN_IP=%%I"

if "%LAN_IP%"=="" set "LAN_IP=127.0.0.1"
if "%BACKEND_PORT%"=="" set "BACKEND_PORT=8000"
if "%FRONTEND_PORT%"=="" set "FRONTEND_PORT=8080"

echo Starting 00631L Flutter web-server for LAN/mobile use.
echo Backend expected at:
echo   http://%LAN_IP%:%BACKEND_PORT%
echo Phone URL after server starts:
echo   http://%LAN_IP%:%FRONTEND_PORT%/#/00631l-lab
echo.
echo If the phone cannot connect, confirm same Wi-Fi and allow Python/Flutter in Windows Firewall.
echo Stop with Ctrl+C.
echo.

flutter run -d web-server --web-hostname 0.0.0.0 --web-port %FRONTEND_PORT% --dart-define=USE_00631L_LIVE_PROXY=true --dart-define=00631L_PROXY_BASE_URL=http://%LAN_IP%:%BACKEND_PORT%
exit /b %ERRORLEVEL%
