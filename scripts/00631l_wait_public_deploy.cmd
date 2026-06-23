@echo off
setlocal
cd /d "%~dp0\.."
py backend\scripts\wait_public_deploy_00631l.py %*
endlocal
