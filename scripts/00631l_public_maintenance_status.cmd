@echo off
setlocal
cd /d "%~dp0\.."
py backend\scripts\public_maintenance_status_00631l.py %*
endlocal
