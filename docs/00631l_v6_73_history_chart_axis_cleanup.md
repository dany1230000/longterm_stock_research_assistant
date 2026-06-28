# 00631L lab v6.73 history chart axis cleanup

v6.73 improves mobile readability for the history/backtest chart area.

## What changed

- Removed the duplicate in-chart x-axis date labels from the reusable history
  chart.
- Kept the dedicated start/middle/end date strip below the chart.
- Kept chart tap detail so users can inspect the exact date and value.

## Why

On phone width, the in-chart x-axis labels could overlap the y-axis labels.
The below-chart date strip already gives clearer range context, so the chart no
longer needs a second set of dates inside the plotting area.

## Scope

This is a presentation-only change. It does not change:

- historical price data,
- split-adjusted calculations,
- backtest formulas,
- selected ETF behavior,
- position tracking,
- AI analysis.
