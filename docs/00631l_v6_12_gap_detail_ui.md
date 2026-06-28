# 00631L lab v6.12 gap detail UI

v6.12 brings ETF price-history gap details into the app settings page.

## What changed

- Added frontend models for symbol-level ETF price-history gap details.
- Added repository support for:
  - live proxy: `GET /api/etf/history/gaps`
  - static public data: `web/00631l-static-data/etf_price_history_gaps.json`
  - cached and mock fallback
- Added an app settings panel named `ETF gap details`.
- The panel shows code, reason, source status, row count, attempt time, and
  short error text for unavailable ETF price histories.

## Data boundary

Gap details are maintenance status only.

Unavailable ETF rows are not used as history, backtest, comparison, or AI
performance data. Only ETFs with verified price-history rows are eligible for
those features.

## Usage

Open:

```text
Settings / ETF data and comparison capability / ETF gap details
```

Use the panel to see why some ETF catalog symbols are not yet history-ready.

For deeper maintenance:

```cmd
scripts\00631l_import_etf_price_history.cmd --status-only --summary-only
scripts\00631l_probe_missing_etf_reasons.cmd
scripts\00631l_export_static_data.cmd --status-only
```

## Validation

This release adds repository and widget coverage for the gap-detail mapping and
settings panel. Full release validation still includes Flutter tests, backend
tests, release check, and `git diff --check`.
