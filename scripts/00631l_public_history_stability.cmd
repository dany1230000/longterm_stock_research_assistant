@echo off
setlocal
cd /d "%~dp0.."
py backend\scripts\public_history_stability_00631l.py %*
