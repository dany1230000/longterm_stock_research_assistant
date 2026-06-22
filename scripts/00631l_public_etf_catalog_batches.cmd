@echo off
setlocal

cd /d "%~dp0.."

py backend\scripts\run_public_etf_catalog_batches_00631l.py %*
exit /b %ERRORLEVEL%
