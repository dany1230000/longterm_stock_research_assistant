@echo off
setlocal
cd /d "%~dp0.."
py backend\scripts\verify_public_persistence_00631l.py %*
