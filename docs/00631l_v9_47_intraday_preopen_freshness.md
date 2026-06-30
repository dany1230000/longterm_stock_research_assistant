# 00631L lab v9.47 - intraday pre-open freshness

Date: 2026-06-30

## Goal

Make the public backend describe pre-open intraday NAV timing the same way as
the Flutter app.

## Change

When the backend is checked before the next regular session and the latest
intraday NAV data is from the previous trading day, `marketSession` now reports:

- `dataFreshness: previous_trading_day_last`
- `dataFreshnessLabel: 前一交易日資料`
- `isDisplayUsable: true`

This keeps the home page and operations status from treating the previous
trading day's closing intraday NAV snapshot as a generic stale error during
pre-open hours.

## Scope

This release changes only intraday market-session freshness labeling. It does
not change TWSE/Yuanta parsing, TX quote sourcing, holdings history,
backtesting, portfolio storage, notifications, or investment guidance.
