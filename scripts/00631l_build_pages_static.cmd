@echo off
setlocal

cd /d "%~dp0.."

call scripts\00631l_import_etf_price_history.cmd --codes 00631L,0050,0056,006208,00692,00713,00757,00850,00878,00881,00919,00922,00923,00929,00940 --start-date 2019-01-01
if errorlevel 1 exit /b %ERRORLEVEL%

call scripts\00631l_export_static_data.cmd --update --strict --min-etf-catalog-row-count 100 --output-dir web\00631l-static-data
if errorlevel 1 exit /b %ERRORLEVEL%

flutter build web --base-href="/longterm_stock_research_assistant/" --dart-define=USE_00631L_STATIC_DATA=true --dart-define=00631L_STATIC_DATA_BASE_URL=00631l-static-data
exit /b %ERRORLEVEL%
