# 00631L v3.47 split-adjusted history summary

Date: 2026-06-13

## Purpose

v3.47 fixes 00631L historical price and backtest calculations around the 2026 beneficial certificate split.

TWSE `STOCK_DAY` raw OHLC prices are still saved and exported. Performance, drawdown, chart series, static public history, CSV export, and backtest calculations now use split-adjusted prices.

## Split Adjustment

- Event: 00631L 1 old unit to 22 new units.
- Effective trading date: 2026-03-31.
- Adjustment: prices before 2026-03-31 use factor `1 / 22`.
- Raw fields remain unchanged: `open`, `high`, `low`, `close`.
- Adjusted fields are added: `adjustedOpen`, `adjustedHigh`, `adjustedLow`, `adjustedClose`, `adjustmentFactor`.
- Return and backtest field: `adjustedClose`.

## Backend Changes

- `backend/app/price_history.py` applies the known split adjustment while reading and parsing price history.
- Existing local JSONL caches are normalized on read, so old raw-only rows no longer create a false split drawdown.
- `backend/app/backtest.py` uses `adjustedClose`.
- `backend/app/history_export.py` exports both raw and adjusted price fields.
- Static public data manifests include price adjustment metadata.

## Frontend Changes

- `EtfPriceHistoryPoint` now carries adjusted price fields.
- Performance summary, drawdown, sparkline, history charts, and local backtest use `performanceClose`, which resolves to `adjustedClose` when available.
- Proxy and static repositories map adjusted price fields from backend/static JSON.

## Validation

Added tests verify that the 2026-03-24 to 2026-03-31 split transition does not create a false near-95% decline in performance or backtest output.

## Scope

This release only fixes historical price normalization. It does not add TX live data, broaden ETF scope, notifications, automated trading, or investment guidance.
