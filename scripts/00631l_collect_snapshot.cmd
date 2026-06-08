@echo off
setlocal

cd /d "%~dp0.."

py backend\scripts\collect_00631l_snapshot.py %*
exit /b %ERRORLEVEL%
