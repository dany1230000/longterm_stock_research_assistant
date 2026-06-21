# 00631L lab v4.35 selected ETF history quality card

v4.35 makes the selected ETF history and backtest page easier to verify.

## What Changed

- The history/backtest page now shows a compact selected ETF history-quality card.
- The card shows symbol, name, row count, coverage range, source status, price field, and adjustment status.
- When the user switches from 00631L to another ETF, the history page now surfaces that ETF's own data coverage instead of relying on the general page header.

## Why

The app is moving toward an ETF research room where users can switch symbols and compare verified history. The selected symbol's data coverage and price-field assumptions must be visible before reading charts or backtest results.

## Scope

- UI and widget test only.
- Uses already loaded price history metadata.
- Does not add TX live, new live holdings sources, notifications, or investment guidance.
