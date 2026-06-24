@echo off
setlocal
cd /d "%~dp0\.."

py backend\scripts\check_public_pages_00631l.py %*
exit /b %ERRORLEVEL%
