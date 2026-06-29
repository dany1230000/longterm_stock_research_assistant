@echo off
setlocal

cd /d "%~dp0.."

py backend\scripts\restore_public_etf_price_history.py --summary-only %*
exit /b %ERRORLEVEL%
