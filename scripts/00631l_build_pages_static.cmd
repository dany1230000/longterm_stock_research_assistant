@echo off
setlocal

cd /d "%~dp0.."

set "FULL_ETF_REFRESH=0"
set "REFRESH_ETF_HISTORY=0"
set "PROBE_MISSING=0"
set "RESTORE_PUBLIC_HISTORY=1"
set "RESTORE_PUBLIC_ATTEMPTS=1"

:parse_args
if "%~1"=="" goto after_args
if /I "%~1"=="--refresh-etf-history" (
    set "REFRESH_ETF_HISTORY=1"
    shift
    goto parse_args
)
if /I "%~1"=="--full-etf-refresh" (
    set "FULL_ETF_REFRESH=1"
    set "REFRESH_ETF_HISTORY=1"
    shift
    goto parse_args
)
if /I "%~1"=="--probe-missing" (
    set "PROBE_MISSING=1"
    shift
    goto parse_args
)
if /I "%~1"=="--restore-public-attempts" (
    set "RESTORE_PUBLIC_ATTEMPTS=1"
    shift
    goto parse_args
)
if /I "%~1"=="--restore-public-history" (
    set "RESTORE_PUBLIC_HISTORY=1"
    shift
    goto parse_args
)
if /I "%~1"=="--skip-restore-public-history" (
    set "RESTORE_PUBLIC_HISTORY=0"
    shift
    goto parse_args
)
if /I "%~1"=="--skip-restore-public-attempts" (
    set "RESTORE_PUBLIC_ATTEMPTS=0"
    shift
    goto parse_args
)
echo Unknown argument: %~1
echo Usage: scripts\00631l_build_pages_static.cmd [--refresh-etf-history] [--full-etf-refresh] [--probe-missing] [--restore-public-history] [--skip-restore-public-history] [--restore-public-attempts] [--skip-restore-public-attempts]
exit /b 2

:after_args

if not "%REFRESH_ETF_HISTORY%%FULL_ETF_REFRESH%%PROBE_MISSING%"=="000" (
    if not exist backend\data mkdir backend\data
    call scripts\00631l_import_etf_catalog.cmd --output backend\data\etf_catalog.json
    if errorlevel 1 (
        echo [00631L] WARN ETF catalog import failed; using committed seed catalog for this local run.
        copy /Y backend\seeds\twse_etf_catalog_seed.json backend\data\etf_catalog.json >nul
    )
) else (
    echo [00631L] Skipping runtime ETF catalog import for fast Pages build.
)

if "%REFRESH_ETF_HISTORY%"=="1" (
    call scripts\00631l_import_etf_price_history.cmd --codes 00631L,0050,0056,006208,00692,00713,00757,00850,00878,00881,00919,00922,00923,00929,00940 --start-date 2019-01-01 --summary-only --progress-every 5
    if errorlevel 1 exit /b %ERRORLEVEL%
) else (
    echo [00631L] Skipping selected ETF price-history refresh for fast Pages build.
    echo [00631L] Run scripts\00631l_build_pages_static.cmd --refresh-etf-history for selected ETF refresh.
)

if "%FULL_ETF_REFRESH%"=="1" (
    call scripts\00631l_import_etf_price_history.cmd --from-catalog --catalog-path backend\data\etf_catalog.json --limit 0 --start-date 2026-06-01 --allow-partial --summary-only --progress-every 25
    if errorlevel 1 exit /b %ERRORLEVEL%
) else (
    echo [00631L] Skipping broad all-catalog ETF recent refresh for fast Pages build.
    echo [00631L] Run scripts\00631l_build_pages_static.cmd --full-etf-refresh for scheduled/manual full refresh.
)

if "%RESTORE_PUBLIC_HISTORY%"=="1" (
    call scripts\00631l_restore_public_price_history.cmd --output-path backend\data\00631l_price_history.jsonl
    if errorlevel 1 exit /b %ERRORLEVEL%
    call scripts\00631l_restore_public_etf_price_history.cmd --output-dir backend\data\etf_price_history
    if errorlevel 1 exit /b %ERRORLEVEL%
) else (
    echo [00631L] Skipping public 00631L and ETF history restore for this local Pages build.
    echo [00631L] Remove --skip-restore-public-history to reuse public static price-history rows.
)

if "%RESTORE_PUBLIC_ATTEMPTS%"=="1" (
    call scripts\00631l_restore_public_etf_attempts.cmd --output-dir backend\data\etf_price_history
    if errorlevel 1 exit /b %ERRORLEVEL%
) else (
    echo [00631L] Skipping public ETF attempt restore for this local Pages build.
    echo [00631L] Remove --skip-restore-public-attempts to reuse public gap evidence.
)

if "%REFRESH_ETF_HISTORY%"=="1" (
    call scripts\00631l_import_missing_etf_batch.cmd --catalog-path backend\data\etf_catalog.json --limit 50 --start-date 2026-06-01 --allow-partial --summary-only --progress-every 10
    if errorlevel 1 exit /b %ERRORLEVEL%
) else (
    echo [00631L] Skipping missing-only ETF history batch for fast Pages build.
)

if "%PROBE_MISSING%"=="1" (
    for /L %%I in (1,1,3) do (
        echo [00631L] Probe missing ETF gap reason batch %%I/3.
        call scripts\00631l_probe_missing_etf_reasons.cmd --catalog-path backend\data\etf_catalog.json --limit 20 --start-date 2026-06-01 --allow-partial --summary-only --progress-every 10
        if errorlevel 1 exit /b %ERRORLEVEL%
    )
) else (
    echo [00631L] Skipping missing ETF reason probe for local fast Pages build.
    echo [00631L] Run scripts\00631l_build_pages_static.cmd --probe-missing to classify a small missing batch.
)

if "%REFRESH_ETF_HISTORY%"=="1" (
    call scripts\00631l_import_tpex_etf_price_history.cmd --from-catalog --missing-only --official-empty-only --catalog-path backend\data\etf_catalog.json --limit 0 --start-date 2026-06-01 --allow-partial --summary-only --progress-every 25
    if errorlevel 1 exit /b %ERRORLEVEL%
) else (
    echo [00631L] Skipping TPEx ETF price-history fallback for fast Pages build.
    echo [00631L] Run scripts\00631l_build_pages_static.cmd --refresh-etf-history to recheck TWSE empty ETFs against TPEx.
)

call scripts\00631l_export_static_data.cmd --update --strict --max-coverage-age-days 7 --min-etf-catalog-row-count 100 --multi-etf-codes all-catalog --output-dir web\00631l-static-data --summary-only
if errorlevel 1 exit /b %ERRORLEVEL%

call scripts\00631l_guard_static_public_regression.cmd --local-dir web\00631l-static-data
if errorlevel 1 exit /b %ERRORLEVEL%

flutter build web --base-href="/longterm_stock_research_assistant/" --dart-define=USE_00631L_STATIC_DATA=true --dart-define=00631L_STATIC_DATA_BASE_URL=00631l-static-data
exit /b %ERRORLEVEL%
