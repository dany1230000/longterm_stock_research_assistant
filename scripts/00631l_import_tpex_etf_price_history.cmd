@echo off
setlocal
cd /d "%~dp0\.."
py backend\scripts\import_tpex_etf_price_history.py %*
