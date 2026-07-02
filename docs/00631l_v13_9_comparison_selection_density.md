# 00631L v13.9 comparison selection density

## Goal

Make the history/backtest ETF comparison area read like a selected comparison
basket instead of a long control panel on phones.

## Changes

- The first comparison screen keeps the selected-basket summary, mode summary,
  readiness strip, and chart/detail entry visible.
- ETF filter chips, manual ETF selection, and quick actions now live under the
  `選擇比較 ETF` expansion panel.
- The copy continues to state that comparison uses a self-selected basket and
  does not set a fixed benchmark.

## Validation

- Updated widget tests so comparison controls are hidden on the first screen and
  appear after expanding `選擇比較 ETF`.
- Verified basket selection still updates the selected ETF list and chart input.
