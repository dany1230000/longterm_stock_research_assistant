@echo off
setlocal EnableExtensions EnableDelayedExpansion

cd /d "%~dp0.."

echo == 00631L deployment bootstrap ==

if exist "C:\src\flutter-clean\bin\flutter.bat" (
    set "PATH=C:\src\flutter-clean\bin;%PATH%"
    echo PASS Flutter clean SDK path preferred.
) else (
    echo WARN C:\src\flutter-clean\bin\flutter.bat was not found.
)

echo.
echo == Backend dependencies ==
py -m pip install -r backend\requirements.txt
if errorlevel 1 (
    echo [summary] overallStatus=FAIL step=backend_dependencies
    exit /b 1
)

echo.
echo == Local env ==
if exist backend\.env (
    echo PASS backend\.env already exists.
) else (
    if exist backend\.env.example (
        copy backend\.env.example backend\.env >nul
        if errorlevel 1 (
            echo FAIL could not create backend\.env from backend\.env.example.
            echo [summary] overallStatus=FAIL step=local_env
            exit /b 1
        )
        echo PASS created backend\.env from backend\.env.example.
    ) else (
        echo FAIL backend\.env.example is missing.
        echo [summary] overallStatus=FAIL step=local_env
        exit /b 1
    )
)

echo.
echo == Local data directories ==
for %%D in (backend\data backend\exports backend\backups backend\reports) do (
    if not exist %%D mkdir %%D
    if exist %%D (
        echo PASS %%D ready.
    ) else (
        echo FAIL %%D could not be created.
        echo [summary] overallStatus=FAIL step=local_directories
        exit /b 1
    )
)

echo.
echo == Environment check ==
call scripts\00631l_check_env.cmd
set "CHECK_EXIT=%ERRORLEVEL%"
if not "%CHECK_EXIT%"=="0" (
    echo [summary] overallStatus=FAIL step=env_check
    exit /b %CHECK_EXIT%
)

echo.
echo == Next commands ==
echo Start backend: scripts\00631l_start_backend.cmd
echo Open frontend live: scripts\00631l_start_frontend_live.cmd
echo Direct route: http://localhost:5000/#/00631l-lab
echo Daily cycle: scripts\00631l_daily_cycle.cmd
echo Release check: scripts\00631l_release_check.cmd

echo [summary] overallStatus=PASS step=bootstrap
exit /b 0
