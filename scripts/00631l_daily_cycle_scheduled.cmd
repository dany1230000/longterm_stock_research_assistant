@echo off
setlocal EnableExtensions

cd /d "%~dp0.."

set "SCHEDULED_DIR=backend\data\scheduled"
if not exist "%SCHEDULED_DIR%" mkdir "%SCHEDULED_DIR%"

for /f %%i in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%i"
if "%STAMP%"=="" set "STAMP=unknown"
set "LOG_PATH=%SCHEDULED_DIR%\00631l_daily_cycle_%STAMP%.log"

echo 00631L scheduled daily cycle
echo Repo: %CD%
echo Log: %LOG_PATH%
echo.

call scripts\00631l_daily_cycle.cmd > "%LOG_PATH%" 2>&1
set "EXIT_CODE=%ERRORLEVEL%"

type "%LOG_PATH%"
echo.
echo Scheduled daily cycle exitCode %EXIT_CODE%
exit /b %EXIT_CODE%
