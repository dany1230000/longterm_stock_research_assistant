@echo off
setlocal

cd /d "%~dp0.."

if "%~1"=="" (
  py backend\scripts\import_etf_price_history.py --from-catalog --missing-only --skip-attempted --limit 25 --allow-partial --summary-only --progress-every 5
  exit /b %ERRORLEVEL%
)

py backend\scripts\import_etf_price_history.py --from-catalog --missing-only --skip-attempted %*
exit /b %ERRORLEVEL%
