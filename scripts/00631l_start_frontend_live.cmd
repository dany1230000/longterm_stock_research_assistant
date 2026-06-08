@echo off
setlocal

cd /d "%~dp0.."

if exist "C:\src\flutter-clean\bin\flutter.bat" (
    set "PATH=C:\src\flutter-clean\bin;%PATH%"
)

echo Starting Flutter live proxy mode for /00631l-lab
echo Backend expected at http://127.0.0.1:8000
call flutter run -d chrome --dart-define=USE_00631L_LIVE_PROXY=true --dart-define=00631L_PROXY_BASE_URL=http://127.0.0.1:8000
exit /b %ERRORLEVEL%
