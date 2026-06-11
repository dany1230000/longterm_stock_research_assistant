@echo off
setlocal

cd /d "%~dp0.."

py backend\scripts\remote_maintenance_00631l.py %*
exit /b %ERRORLEVEL%
