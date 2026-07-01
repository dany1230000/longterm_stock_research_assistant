# 00631L v9.92 history top strip density

## Scope

v9.92 tightens the mobile history/backtest top strip.

## Changes

- Keeps the bottom navigation label short while the page itself still contains
  both history and backtest tools.
- Shows the selected ETF name, data range, row count, and default one-year
  range in a compact first strip.
- Hides the lower-priority history contract badge on narrow screens while
  keeping the source-status badge visible.
- Adds a phone-width widget guard for the compact top strip.

## Data behavior

No historical data calculation, split adjustment, backtest logic, export, or
source-status behavior changed.
