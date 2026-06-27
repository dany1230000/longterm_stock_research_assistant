@echo off
setlocal

cd /d "%~dp0.."

py backend\scripts\guard_static_public_regression_00631l.py %*
exit /b %ERRORLEVEL%
