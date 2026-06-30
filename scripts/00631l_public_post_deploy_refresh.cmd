@echo off
setlocal

cd /d "%~dp0.."

py backend\scripts\public_post_deploy_refresh_00631l.py %*
exit /b %ERRORLEVEL%
