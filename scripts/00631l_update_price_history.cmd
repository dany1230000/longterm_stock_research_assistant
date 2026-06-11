@echo off
setlocal

cd /d "%~dp0.."

py backend\scripts\update_00631l_price_history.py %*
exit /b %ERRORLEVEL%
