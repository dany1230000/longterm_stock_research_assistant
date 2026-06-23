@echo off
setlocal
cd /d "%~dp0\.."
py backend\scripts\check_public_deploy_drift_00631l.py %*
endlocal
