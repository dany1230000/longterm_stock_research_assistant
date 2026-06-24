@echo off
setlocal
cd /d "%~dp0\.."

py backend\scripts\public_pages_checkup_00631l.py %*
exit /b %ERRORLEVEL%
