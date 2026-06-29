@echo off
setlocal

cd /d "%~dp0.."

echo [00631L] Checking static first-load request budget...
call flutter test test\etf_00631l_proxy_repository_test.dart --plain-name "static fast lab data defers full ETF catalog files"
if errorlevel 1 (
  echo [00631L] FAIL: static first screen requested full ETF catalog or history index.
  exit /b 1
)

echo [00631L] PASS: static first screen defers full ETF catalog and history index.
exit /b 0
