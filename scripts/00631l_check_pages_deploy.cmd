@echo off
setlocal
cd /d "%~dp0\.."

py backend\scripts\check_pages_deploy_status_00631l.py %*
exit /b %ERRORLEVEL%
