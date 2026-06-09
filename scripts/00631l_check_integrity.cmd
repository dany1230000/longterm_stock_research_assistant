@echo off
setlocal

cd /d "%~dp0.."

py backend\scripts\check_00631l_data_integrity.py %*
exit /b %ERRORLEVEL%
