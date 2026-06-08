@echo off
setlocal

cd /d "%~dp0.."

echo == 00631L collect snapshot ==
call scripts\00631l_collect_snapshot.cmd --samples 1 || exit /b %ERRORLEVEL%

echo.
echo == 00631L export history ==
call scripts\00631l_export_history.cmd || exit /b %ERRORLEVEL%

echo.
echo == 00631L live smoke ==
call scripts\00631l_daily_smoke.cmd || exit /b %ERRORLEVEL%

echo.
echo 00631L daily cycle finished.
