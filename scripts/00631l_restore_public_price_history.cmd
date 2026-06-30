@echo off
setlocal

cd /d "%~dp0.."
py backend\scripts\restore_public_00631l_price_history.py --summary-only %*
