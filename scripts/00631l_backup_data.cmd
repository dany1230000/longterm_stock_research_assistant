@echo off
setlocal

cd /d "%~dp0.."

py backend\scripts\backup_00631l_data.py %*
exit /b %ERRORLEVEL%
