@echo off
setlocal EnableDelayedExpansion

cd /d "%~dp0.."

set "ROOT_URL=%~1"
if "%ROOT_URL%"=="" set "ROOT_URL=https://dany1230000.github.io/longterm_stock_research_assistant/"

where npx.cmd >nul 2>&1
if errorlevel 1 (
  echo [00631L] WARN: npx.cmd not available; skipping public console smoke.
  exit /b 0
)

set "CONSOLE_LOG=%TEMP%\00631l_public_console_%RANDOM%_%RANDOM%.txt"

echo [00631L] Checking public console: %ROOT_URL%
call npx.cmd --yes --package @playwright/cli playwright-cli close-all >nul 2>&1
call npx.cmd --yes --package @playwright/cli playwright-cli open "%ROOT_URL%" >nul
if errorlevel 1 (
  echo [00631L] FAIL: unable to open public app.
  exit /b 1
)

call npx.cmd --yes --package @playwright/cli playwright-cli resize 393 852 >nul
ping -n 4 127.0.0.1 >nul
call npx.cmd --yes --package @playwright/cli playwright-cli console > "%CONSOLE_LOG%"
set "CONSOLE_EXIT=%ERRORLEVEL%"
call npx.cmd --yes --package @playwright/cli playwright-cli close-all >nul 2>&1
if exist ".playwright-cli" rmdir /s /q ".playwright-cli" >nul 2>&1

if not "%CONSOLE_EXIT%"=="0" (
  echo [00631L] FAIL: unable to read public console.
  if exist "%CONSOLE_LOG%" type "%CONSOLE_LOG%"
  exit /b 1
)

findstr /C:"Errors: 0, Warnings: 0" "%CONSOLE_LOG%" >nul 2>&1
if errorlevel 1 (
  echo [00631L] FAIL: public console contains errors or warnings. Log: %CONSOLE_LOG%
  type "%CONSOLE_LOG%"
  exit /b 1
)

del "%CONSOLE_LOG%" >nul 2>&1
echo [00631L] PASS: public console has no errors or warnings.
exit /b 0
