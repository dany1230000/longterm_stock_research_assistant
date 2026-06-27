@echo off
setlocal

cd /d "%~dp0.."

py backend\scripts\restore_public_etf_attempts.py --summary-only %*
exit /b %ERRORLEVEL%
