@echo off
setlocal

cd /d "%~dp0.."

set "FULL_ETF_REFRESH=0"

:parse_args
if "%~1"=="" goto after_args
if /I "%~1"=="--full-etf-refresh" (
    set "FULL_ETF_REFRESH=1"
    shift
    goto parse_args
)
echo Unknown argument: %~1
echo Usage: scripts\00631l_build_pages_static.cmd [--full-etf-refresh]
exit /b 2

:after_args

call scripts\00631l_import_etf_price_history.cmd --codes 00631L,0050,0056,006208,00692,00713,00757,00850,00878,00881,00919,00922,00923,00929,00940 --start-date 2019-01-01 --summary-only --progress-every 5
if errorlevel 1 exit /b %ERRORLEVEL%

if "%FULL_ETF_REFRESH%"=="1" (
    call scripts\00631l_import_etf_price_history.cmd --from-catalog --catalog-path backend\seeds\twse_etf_catalog_seed.json --limit 0 --start-date 2026-06-01 --allow-partial --summary-only --progress-every 25
    if errorlevel 1 exit /b %ERRORLEVEL%
) else (
    echo [00631L] Skipping broad all-catalog ETF recent refresh for fast Pages build.
    echo [00631L] Run scripts\00631l_build_pages_static.cmd --full-etf-refresh for scheduled/manual full refresh.
)

call scripts\00631l_import_missing_etf_batch.cmd --catalog-path backend\seeds\twse_etf_catalog_seed.json --limit 50 --start-date 2026-06-01 --allow-partial --summary-only --progress-every 10
if errorlevel 1 exit /b %ERRORLEVEL%

call scripts\00631l_export_static_data.cmd --update --strict --max-coverage-age-days 7 --min-etf-catalog-row-count 100 --multi-etf-codes all-catalog --output-dir web\00631l-static-data --summary-only
if errorlevel 1 exit /b %ERRORLEVEL%

flutter build web --base-href="/longterm_stock_research_assistant/" --dart-define=USE_00631L_STATIC_DATA=true --dart-define=00631L_STATIC_DATA_BASE_URL=00631l-static-data
exit /b %ERRORLEVEL%
