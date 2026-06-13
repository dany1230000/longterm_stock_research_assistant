# 00631L lab v3.38 history backtest merge summary

Completed: 2026-06-13

## Scope

v3.38 removes the secondary history/backtest switch inside the bottom
navigation page.

## Changes

- The bottom navigation still has one `歷史回測` destination.
- The page now starts with historical coverage, historical metrics, and
  holdings history.
- The backtest tool stays on the same page behind a compact expansion panel, so
  it is available without competing with the first historical data screen.

## Notes

- Backtest output remains based only on saved historical prices.
- Backtests are historical calculations and do not represent future results.
- This release does not add any trading workflow or live TX integration.
