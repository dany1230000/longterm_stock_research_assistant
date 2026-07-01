# 00631L v9.93 symbol search capability badges

## Scope

v9.93 improves the left-top ETF search sheet readability.

## Changes

- Shows history and backtest capability badges directly in ETF search results.
- Keeps live NAV scope visible so non-00631L ETFs are not mistaken for live NAV
  capable symbols.
- Preserves the existing search ranking, ETF switching, and stock search flow.
- Adds a widget guard that a ready ETF result shows `歷史可用` and `回測可用`
  in the result tile.

## Data behavior

No ETF data import, history calculation, split adjustment, or live backend
behavior changed.
