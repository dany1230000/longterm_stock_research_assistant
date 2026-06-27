@echo off
setlocal

cd /d "%~dp0.."

py backend\scripts\import_etf_price_history.py --from-catalog --missing-only --allow-partial --limit 20 --progress-every 10 --summary-only %*
exit /b %ERRORLEVEL%
