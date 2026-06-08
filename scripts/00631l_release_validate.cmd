@echo off
setlocal

cd /d "%~dp0.."

if exist "C:\src\flutter-clean\bin\flutter.bat" (
    set "PATH=C:\src\flutter-clean\bin;%PATH%"
    echo Prepended Flutter SDK: C:\src\flutter-clean\bin
) else (
    echo Flutter SDK path not found: C:\src\flutter-clean\bin
    echo Continuing with Flutter from PATH.
)

echo.
echo == flutter analyze ==
call flutter analyze || exit /b %ERRORLEVEL%

echo.
echo == flutter test ==
call flutter test || exit /b %ERRORLEVEL%

echo.
echo == flutter build web ==
call flutter build web || exit /b %ERRORLEVEL%

echo.
echo == backend tests ==
py -m unittest discover -s backend\tests || exit /b %ERRORLEVEL%

if /i "%~1"=="--skip-smoke" goto diff_check

echo.
echo == 00631L live smoke ==
call scripts\00631l_daily_smoke.cmd || exit /b %ERRORLEVEL%

:diff_check
echo.
echo == git diff --check ==
git diff --check || exit /b %ERRORLEVEL%

echo.
echo 00631L release validation finished.
