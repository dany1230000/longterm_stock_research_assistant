@echo off
setlocal

cd /d "%~dp0.."

if /i "%~1"=="--no-env-file" goto run_smoke

set "ENV_PATH=backend\.env"
if not "%~1"=="" set "ENV_PATH=%~1"

if exist "%ENV_PATH%" (
    for /f "usebackq eol=# tokens=1,* delims==" %%A in ("%ENV_PATH%") do (
        if not "%%B"=="" set "%%A=%%B"
    )
    echo Loaded %ENV_PATH%
) else (
    echo Env file not found: %ENV_PATH%
    echo Copy backend\.env.example to backend\.env to enable live intraday URLs.
)

:run_smoke
py backend\scripts\smoke_00631l_live.py
exit /b %ERRORLEVEL%
