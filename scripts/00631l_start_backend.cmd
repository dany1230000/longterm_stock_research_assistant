@echo off
setlocal

cd /d "%~dp0.."

echo Starting 00631L backend proxy at http://127.0.0.1:8000
echo Press Ctrl+C to stop.
py -m uvicorn backend.app.main:app --reload --host 127.0.0.1 --port 8000
exit /b %ERRORLEVEL%
