@echo off
setlocal

cd /d "%~dp0.."

py backend\scripts\check_public_static_data_00631l.py %*
exit /b %ERRORLEVEL%
