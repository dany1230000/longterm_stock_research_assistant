@echo off
setlocal

cd /d "%~dp0.."

if exist "C:\src\flutter-clean\bin\flutter.bat" (
    set "PATH=C:\src\flutter-clean\bin;%PATH%"
)

set "MOBILE_TESTS=00631L lab renders stock-app style quote header|00631L lab remains readable on phone width|phone tabs open distinct first-screen content|overview phone first screen keeps market order|overview chart shows one-year label and date axis|overview includes official holdings context on phone|history range context wraps on phone width|empty position starts with input card on phone width|position phone values keep summary first without duplicate grid|backtest quick result stays compact on phone width|top symbol search result stays compact on phone width|ETF comparison action strip uses compact labels on phone width|AI phone first screen keeps long details collapsed|settings first screen keeps technical diagnostics advanced|day and night mode toggle changes the market palette"

echo [00631L] Mobile layout check
echo [00631L] Verifies quote density, first-screen order, digest tape, phone tabs, compact controls, search, AI, settings, and theme switching.
call flutter test test\etf_00631l_widget_test.dart --name "%MOBILE_TESTS%"
if errorlevel 1 (
    echo [00631L] FAIL: mobile layout check failed.
    exit /b 1
)

echo [00631L] PASS: mobile layout check passed.
