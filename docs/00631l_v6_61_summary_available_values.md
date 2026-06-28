# 00631L lab v6.61 summary available values

v6.61 makes the first-screen DAY / LIVE / HIS row prefer real available values
over generic background-refresh words.

## What changed

- DAY shows the official holdings date when the snapshot is usable.
- LIVE shows the intraday NAV time when it is available.
- HIS continues to show row count and coverage when static/public history is
  available.
- `syncing` and `checking` are now used only for the specific missing data item.

## Why

The first screen should read like a market app: if data is already available,
show the data. Background refresh state remains useful only when a specific
source has not returned a usable value yet.

## Scope

This is a display change only. It does not change:

- official holdings parsing,
- intraday NAV parsing,
- static price history,
- selected ETF search,
- backtest formulas,
- position tracking,
- AI analysis.
