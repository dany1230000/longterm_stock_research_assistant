@echo off
setlocal

cd /d "%~dp0.."

echo 00631L lab daily open helper
echo Repo: %CD%
echo.

echo [1/4] Checking local environment...
call scripts\00631l_check_env.cmd
set "CHECK_EXIT=%ERRORLEVEL%"
echo.

if not "%CHECK_EXIT%"=="0" (
    echo Environment check returned exit code %CHECK_EXIT%.
    echo Review the messages above before starting the lab.
    echo.
)

echo [2/4] Checking backend health at http://127.0.0.1:8000/health
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $r = Invoke-RestMethod 'http://127.0.0.1:8000/health' -TimeoutSec 3; Write-Host ('Backend reachable: ' + $r.status) } catch { Write-Host 'Backend is not reachable yet. Start it in a separate terminal.' }"
echo.

echo [3/4] Start commands
echo Backend terminal:
echo   scripts\00631l_start_backend.cmd
echo.
echo Daily cycle terminal or after backend is ready:
echo   scripts\00631l_daily_cycle.cmd
echo.
echo Frontend live terminal:
echo   scripts\00631l_start_frontend_live.cmd
echo.

echo [4/4] Direct page
echo After Flutter opens Chrome, use:
echo   http://127.0.0.1:^<flutter-port^>/#/00631l-lab
echo.
echo The app shell is still the long-term research assistant; /#/00631l-lab is the dedicated 00631L lab route.
exit /b 0
