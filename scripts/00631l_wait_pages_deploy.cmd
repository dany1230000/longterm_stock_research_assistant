@echo off
setlocal
cd /d "%~dp0\.."

py backend\scripts\wait_pages_deploy_00631l.py %*
exit /b %ERRORLEVEL%
