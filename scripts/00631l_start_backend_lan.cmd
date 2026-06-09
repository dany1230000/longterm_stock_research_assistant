@echo off
setlocal

cd /d "%~dp0.."

if "%BACKEND_PORT%"=="" set "BACKEND_PORT=8000"

call scripts\00631l_lan_info.cmd
echo Starting 00631L backend proxy on 0.0.0.0:%BACKEND_PORT%
echo Stop with Ctrl+C.
echo.

py -m uvicorn backend.app.main:app --reload --host 0.0.0.0 --port %BACKEND_PORT%
exit /b %ERRORLEVEL%
