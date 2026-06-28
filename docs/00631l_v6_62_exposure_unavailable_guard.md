# 00631L lab v6.62 exposure unavailable guard

v6.62 prevents invalid official-holdings snapshots from rendering as zero-value
exposure data on the overview chart panel.

## What changed

- The overview exposure strip now renders only when the official holdings
  snapshot is usable.
- A usable snapshot must have positive fund net asset value, positive
  outstanding units, and at least one holdings/cash line.
- When holdings are unavailable, the chart remains visible and the later
  holdings-status card explains the unavailable state.
- Widget tests verify that the exposure strip is present for valid holdings and
  absent for invalid snapshots.

## Why

Showing `0.00%` stock/futures/cash values beside an unavailable holdings state
looked like valid official data. The app should hide invalid derived values
instead of rendering zeros.

## Scope

This is a display guard only. It does not change:

- Yuanta holdings parsing,
- static price history,
- intraday NAV data,
- selected ETF behavior,
- backtest formulas,
- position tracking,
- AI analysis.
