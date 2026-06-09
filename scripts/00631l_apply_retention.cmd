@echo off
setlocal
cd /d "%~dp0\.."

py backend\scripts\apply_00631l_retention.py %*
exit /b %ERRORLEVEL%
