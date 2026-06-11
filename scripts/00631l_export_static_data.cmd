@echo off
setlocal

cd /d "%~dp0.."

py backend\scripts\export_static_00631l_data.py %*
exit /b %ERRORLEVEL%
