@echo off
setlocal

cd /d "%~dp0.."

py backend\scripts\generate_00631l_daily_report.py %*
exit /b %ERRORLEVEL%
