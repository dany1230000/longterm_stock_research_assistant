@echo off
setlocal

cd /d "%~dp0.."

py backend\scripts\restore_00631l_dry_run.py %*
exit /b %ERRORLEVEL%
