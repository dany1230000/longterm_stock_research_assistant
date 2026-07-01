# 00631L lab v9.76 - History Range Panel

## Scope

This release tightens the mobile history/backtest page layout.

## Changes

- Merged the range chips, current range summary, and start/end date buttons into one compact date-range panel.
- Kept the default history and backtest window at the latest one year.
- Kept direct start/end date controls visible on the history and backtest page.
- Reduced duplicated range summary blocks before the history chart and backtest result.
- Preserved the existing history, backtest, ETF comparison, and split-adjusted price behavior.

## Data Notes

- Historical price charts and backtests use the loaded verified price history only.
- The selected range controls both chart metrics and backtest calculations.
- Backtests remain historical calculations only and do not represent future performance.
