@echo off
setlocal

cd /d "%~dp0.."

py backend\scripts\release_check_00631l.py %*
exit /b %ERRORLEVEL%
