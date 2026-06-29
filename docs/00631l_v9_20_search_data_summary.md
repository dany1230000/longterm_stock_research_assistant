# 00631L lab v9.20 search data summary

Date: 2026-06-29

## What changed

- ETF search results now include a compact data summary line.
- The summary shows whether historical data is available, the coverage range, row count, and price basis.
- Catalog-only results explain that historical data still needs to be filled before history, backtest, and comparison views can use them.

## Why

Switching ETFs should not feel like the app failed to load data. The search sheet now tells users what data is ready before they open an ETF.

## Verification

- Widget coverage checks the 0050 search result exposes the data summary key.
- The summary must mention historical data and data basis.
- Existing lazy catalog, ranking, and forbidden wording checks remain active.
