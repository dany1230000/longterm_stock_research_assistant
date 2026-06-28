# 00631L lab v6.74 history range context fit

v6.74 improves the history/backtest page on phone width.

## What changed

- The current chart range metric strip now wraps into two columns on compact
  screens instead of clipping in a horizontal row.
- Mini chart cards are taller on compact screens so the chart, date strip, and
  tap detail can fit without layout overflow.
- The wider desktop layout still uses the compact horizontal metric strip.

## Why

Public mobile inspection after v6.73 showed that the date labels were cleaner,
but the range context cards could still be truncated on phone width. The same
view also exposed that compact mini chart cards were too short for their
interactive date/value detail.

## Scope

This is a presentation-only change. It does not change:

- historical price data,
- split-adjusted calculations,
- backtest formulas,
- selected ETF behavior,
- position tracking,
- AI analysis.
