@echo off
setlocal

cd /d "%~dp0.."

py backend\scripts\export_00631l_history.py %*
exit /b %ERRORLEVEL%
