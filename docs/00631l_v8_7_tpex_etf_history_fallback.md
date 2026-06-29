# 00631L lab v8.7 TPEx ETF history fallback

v8.7 adds an official TPEx daily ETF price-history fallback for ETF symbols that
return empty TWSE `STOCK_DAY` rows.

## What changed

- Added parser/fetcher for the TPEx `ETFReport/historical` daily JSON endpoint.
- Added `scripts\00631l_import_tpex_etf_price_history.cmd`.
- Added `TPEX_ETF_PRICE_HISTORY_URL` to backend environment config.
- GitHub Pages scheduled/static builds can now recheck TWSE empty ETF symbols
  against TPEx before exporting static data.
- Source rows imported from TPEx are labeled with
  `sourceContract=tpex_etf_historical_daily_json`.

## Why it matters

Some ETF symbols, especially bond or OTC ETF symbols, are not covered by TWSE
`STOCK_DAY` even though TPEx publishes official daily OHLC rows. This fallback
keeps the data source official and avoids treating TPEx rows as TWSE rows.

## Local checks

```cmd
scripts\00631l_import_tpex_etf_price_history.cmd --from-catalog --missing-only --official-empty-only --start-date 2026-06-01 --allow-partial --summary-only --progress-every 25
scripts\00631l_import_etf_price_history.cmd --status-only --summary-only
```

The first command rechecks classified official-empty ETF symbols against TPEx.
The second command shows the combined ETF price-history readiness state.

## Current observed result

After the TPEx fallback, local ETF price-history readiness reached `346/347`
with `source_error=0` and one remaining `official_empty` symbol. The remaining
symbol stays unavailable because neither official path produced usable rows for
the checked period.

## Boundary

No synthetic rows are generated. TPEx rows remain a distinct official source,
and symbols with no official rows remain unavailable.
