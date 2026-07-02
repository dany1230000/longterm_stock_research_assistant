# 00631L v13.6 history axis density

## Goal

Make the history/backtest chart date axis easier to read on phone width without
losing detailed date information.

## Changes

- Compact chart axis labels now use short role labels: `起`, `中`, `迄`.
- Compact axis dates use `yy/MM/dd`, reducing text shrink inside the three
  axis chips.
- Touch details still show the full `yyyy/MM/dd` date and selected value.

## Validation

- Added widget coverage for the compact axis labels.
- Existing tests continue to verify chart touch details and axis keys.
