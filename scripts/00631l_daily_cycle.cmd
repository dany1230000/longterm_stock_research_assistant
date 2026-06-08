@echo off
setlocal

cd /d "%~dp0.."

py backend\scripts\run_00631l_daily_cycle.py %*
exit /b %ERRORLEVEL%
