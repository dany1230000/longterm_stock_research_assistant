@echo off
setlocal

cd /d "%~dp0.."

py backend\scripts\check_public_console_00631l.py %*
exit /b %ERRORLEVEL%
