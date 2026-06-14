# 00631L lab v4.9 ETF history selection summary

v4.9 connects the ETF catalog/search entry to selected ETF price history.

## Completed

- Added `fetchEtfPriceHistory(code)` to the frontend repository contract.
- Proxy mode reads `/api/etf/history/price?code=<ETF_CODE>`.
- Static public mode reads `00631l-static-data/etf_price_history/<ETF_CODE>.json`.
- Mock mode returns separate sample history for `0050`, `006208`, `00878`, `00919`, and `00631L`.
- The top-left ETF code selector can switch the history/backtest view to a selected ETF.
- The ETF catalog list can also select a code for history/backtest.
- GitHub Pages static build now imports selected ETF history before exporting static data.

## Data Contract

- `00631L` official holdings and intraday NAV remain 00631L-only.
- Selected ETF price history is TWSE `STOCK_DAY` cached/static data.
- Static public selected ETF history is historical price data only.
- Live intraday NAV still requires a public backend.
- Missing selected ETF history must show unavailable/error state and must not be labeled as official live data.

## Scripts

```cmd
scripts\00631l_import_etf_price_history.cmd --codes 0050,006208,00878,00919,00631L
scripts\00631l_export_static_data.cmd --update
scripts\00631l_build_pages_static.cmd
```

## Validation

- Backend static export tests cover selected ETF JSON output.
- Frontend repository tests cover proxy and static selected ETF history mapping.
- Widget tests cover selecting `0050` from the top ETF search and rendering history/backtest.
