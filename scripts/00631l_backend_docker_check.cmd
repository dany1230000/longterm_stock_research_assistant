@echo off
setlocal
cd /d "%~dp0\.."

py backend\scripts\backend_docker_check_00631l.py %*
exit /b %ERRORLEVEL%
