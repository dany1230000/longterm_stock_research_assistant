@echo off
setlocal
cd /d "%~dp0\.."

py backend\scripts\compare_public_data_freshness_00631l.py %*
exit /b %ERRORLEVEL%
