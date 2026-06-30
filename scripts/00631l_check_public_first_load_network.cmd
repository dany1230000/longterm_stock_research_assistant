@echo off
setlocal EnableDelayedExpansion

cd /d "%~dp0.."

set "ROOT_URL=%~1"
if "%ROOT_URL%"=="" set "ROOT_URL=https://dany1230000.github.io/longterm_stock_research_assistant/"

where npx.cmd >nul 2>&1
if errorlevel 1 (
  echo [00631L] WARN: npx.cmd not available; skipping public first-load network smoke.
  exit /b 0
)

set "REQUEST_LOG=%TEMP%\00631l_first_load_requests_%RANDOM%_%RANDOM%.txt"

echo [00631L] Checking public first-load network budget: %ROOT_URL%
call npx.cmd --yes --package @playwright/cli playwright-cli close-all >nul 2>&1
call npx.cmd --yes --package @playwright/cli playwright-cli open "%ROOT_URL%" >nul
if errorlevel 1 (
  echo [00631L] FAIL: unable to open public app.
  exit /b 1
)

call npx.cmd --yes --package @playwright/cli playwright-cli resize 393 852 >nul
ping -n 4 127.0.0.1 >nul
call npx.cmd --yes --package @playwright/cli playwright-cli requests > "%REQUEST_LOG%"
set "REQUEST_EXIT=%ERRORLEVEL%"
call npx.cmd --yes --package @playwright/cli playwright-cli close-all >nul 2>&1
if exist ".playwright-cli" rmdir /s /q ".playwright-cli" >nul 2>&1

if not "%REQUEST_EXIT%"=="0" (
  echo [00631L] FAIL: unable to read first-load requests.
  if exist "%REQUEST_LOG%" type "%REQUEST_LOG%"
  exit /b 1
)

set "FAILURES=0"
call :forbid "/api/etf/00631l/history/price"
call :forbid "/api/etf/catalog"
call :forbid "/api/etf/00631l/operations/status"
call :forbid "/api/etf/00631l/analysis/summary"
call :forbid "price_history.json"
call :forbid "etf_catalog.json"
call :forbid "etf_price_history_index.json"

if not "%FAILURES%"=="0" (
  echo [00631L] FAIL: first screen requested deferred heavy data. Log: %REQUEST_LOG%
  type "%REQUEST_LOG%"
  exit /b 1
)

del "%REQUEST_LOG%" >nul 2>&1
echo [00631L] PASS: public first screen stays on fast live core plus static preview data.
exit /b 0

:forbid
findstr /C:%1 "%REQUEST_LOG%" >nul 2>&1
if not errorlevel 1 (
  echo [00631L] forbidden first-load request matched %~1
  set /a FAILURES+=1
)
exit /b 0
