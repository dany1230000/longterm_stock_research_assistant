# 00631L v16.72 History Backtest Navigation

This release clarifies the bottom navigation label for the combined history and backtest page.

## Changes

- Bottom navigation changes the history/backtest tab label from `歷史` to `歷回`.
- The page content and title remain focused on historical data, backtest, and ETF comparison.
- The bottom navigation still has no separate ETF tab.
- No data source, parser, chart, backtest, or comparison behavior changed.

## Validation

- Phone navigation widget tests verify the updated label.
- Existing tests still confirm that the ETF research and comparison details live inside the history/backtest flow instead of the bottom nav.
