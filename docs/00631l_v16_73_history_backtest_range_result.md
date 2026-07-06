# 00631L v16.73 History Backtest Range Result

This release tightens the history/backtest first screen for phone use.

## Changes

- Adds a compact range-result strip immediately below the date controls.
- Shows selected-period return, max drawdown, sample count, and latest close before the chart.
- Moves annualized return, annualized volatility, and detailed metric cards into an expandable panel.
- Keeps the default history window at the latest 1 year and keeps date buttons visible.
- Keeps the chart open by default and keeps the tap detail/date axis behavior unchanged.

## Scope

- No data source, parser, backtest engine, or ETF comparison behavior changed.
- No TX live change.
- No investment guidance was added.

## Validation

- Widget tests cover the new range-result strip and compact history layout.
- Full release check remains expected to allow WARN only when failures are empty.
