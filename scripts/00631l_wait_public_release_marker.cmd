@echo off
setlocal
cd /d "%~dp0\.."

py backend\scripts\wait_public_release_marker_00631l.py %*
exit /b %ERRORLEVEL%
