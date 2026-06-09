@echo off
setlocal
cd /d "%~dp0\.."

py backend\scripts\deploy_precheck_00631l.py %*
exit /b %ERRORLEVEL%
