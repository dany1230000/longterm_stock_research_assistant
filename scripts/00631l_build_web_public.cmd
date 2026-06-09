@echo off
setlocal
cd /d "%~dp0\.."

set "PUBLIC_BACKEND_URL_EFFECTIVE=%PUBLIC_BACKEND_URL%"

if "%PUBLIC_BACKEND_URL_EFFECTIVE%"=="" (
  for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "[Environment]::GetEnvironmentVariable('00631L_PUBLIC_BACKEND_URL', 'Process')"`) do set "PUBLIC_BACKEND_URL_EFFECTIVE=%%A"
)

if "%PUBLIC_BACKEND_URL_EFFECTIVE%"=="" (
  set "PUBLIC_BACKEND_URL_EFFECTIVE=https://your-backend.example.com"
  echo [WARN] PUBLIC_BACKEND_URL is not set.
  echo [WARN] Building with placeholder backend URL: https://your-backend.example.com
  echo [WARN] Rebuild with PUBLIC_BACKEND_URL=https://your-backend.example.com before publishing.
)

echo Building 00631L public Flutter web app.
echo Backend API base URL: %PUBLIC_BACKEND_URL_EFFECTIVE%

flutter build web --dart-define=USE_00631L_LIVE_PROXY=true --dart-define=00631L_PROXY_BASE_URL=%PUBLIC_BACKEND_URL_EFFECTIVE%
exit /b %ERRORLEVEL%
