@echo off
setlocal

cd /d "%~dp0.."
py backend\scripts\import_etf_catalog.py %*

endlocal
