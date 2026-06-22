@echo off
setlocal
cd /d "%~dp0\.."

py backend\scripts\public_backend_status_00631l.py %*
exit /b %ERRORLEVEL%
