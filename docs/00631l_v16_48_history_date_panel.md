# 00631L lab v16.48 history date panel

This release tightens the phone history/backtest first screen.

## Changes

- The compact date range panel now combines the title and current range metrics
  into one line.
- Preset chips and start/end date controls stay visible, but the chart appears
  sooner on phone screens.
- Existing custom date selection, one-year default, three-year range, and full
  range controls remain unchanged.

## Scope

- No historical price, split-adjustment, performance, or backtest calculation
  changes.
- No data-source behavior changes.
- The backtest disclaimer remains visible elsewhere in the history/backtest
  flow.

## Validation

- Widget coverage lowers the compact date panel height guard and keeps the
  range, preset, and start/end controls present.
