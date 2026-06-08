@echo off
setlocal EnableExtensions EnableDelayedExpansion

cd /d "%~dp0.."

if exist "C:\src\flutter-clean\bin\flutter.bat" (
    set "PATH=C:\src\flutter-clean\bin;%PATH%"
)

set "WARN=0"
set "FAIL=0"
set "TMP_FLUTTER=%TEMP%\00631l_flutter_path.txt"
set "TMP_DART=%TEMP%\00631l_dart_path.txt"

echo == 00631L local environment check ==

echo.
echo == Flutter path ==
where flutter > "%TMP_FLUTTER%" 2>nul
if errorlevel 1 (
    echo FAIL flutter was not found on PATH.
    set "FAIL=1"
) else (
    type "%TMP_FLUTTER%"
    findstr /i /c:"C:\src\flutter-clean\bin" "%TMP_FLUTTER%" >nul
    if errorlevel 1 (
        echo WARN Flutter PATH does not include C:\src\flutter-clean\bin.
        set "WARN=1"
    ) else (
        echo PASS Flutter clean SDK path found.
    )
)

echo.
echo == Dart path ==
where dart > "%TMP_DART%" 2>nul
if errorlevel 1 (
    echo FAIL dart was not found on PATH.
    set "FAIL=1"
) else (
    type "%TMP_DART%"
)

echo.
echo == Tool versions ==
call flutter --version
if errorlevel 1 set "FAIL=1"
call dart --version
if errorlevel 1 set "FAIL=1"
py --version
if errorlevel 1 (
    echo FAIL Python launcher py was not found.
    set "FAIL=1"
)

echo.
echo == Backend dependencies ==
py -c "import fastapi, uvicorn; print('PASS backend dependencies available')"
if errorlevel 1 (
    echo FAIL backend dependencies missing. Run: py -m pip install -r backend\requirements.txt
    set "FAIL=1"
)

echo.
echo == Local env ==
if exist backend\.env (
    echo PASS backend\.env exists.
    findstr /b /c:"TWSE_00631L_INTRADAY_NAV_URL=" backend\.env >nul
    if errorlevel 1 (
        echo WARN TWSE_00631L_INTRADAY_NAV_URL is not set in backend\.env.
        set "WARN=1"
    ) else (
        echo PASS TWSE_00631L_INTRADAY_NAV_URL is configured.
    )
    findstr /b /c:"YUANTA_00631L_INTRADAY_NAV_URL=" backend\.env >nul
    if errorlevel 1 (
        echo WARN YUANTA_00631L_INTRADAY_NAV_URL is not set. This is allowed if TWSE is configured.
        set "WARN=1"
    ) else (
        echo PASS YUANTA_00631L_INTRADAY_NAV_URL is configured.
    )
) else (
    echo WARN backend\.env does not exist.
    echo      Optional setup: copy backend\.env.example backend\.env
    echo      Without backend\.env, intraday NAV may be unavailable in local scripts.
    set "WARN=1"
)

echo.
echo == Local data directories ==
for %%D in (backend\data backend\exports) do (
    if not exist %%D mkdir %%D
    if exist %%D (
        echo PASS %%D exists.
    ) else (
        echo FAIL %%D could not be created.
        set "FAIL=1"
    )
)

del "%TMP_FLUTTER%" >nul 2>nul
del "%TMP_DART%" >nul 2>nul

echo.
if "%FAIL%"=="1" (
    echo overallStatus FAIL
    exit /b 1
)
if "%WARN%"=="1" (
    echo overallStatus WARN
    exit /b 0
)
echo overallStatus PASS
exit /b 0
