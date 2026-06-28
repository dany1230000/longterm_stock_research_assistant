# 00631L lab v6.16 selected ETF capability badges

v6.16 makes the selected ETF state easier to read after using the top-left
symbol search.

## What changed

- The selected ETF readiness banner now shows compact capability badges:
  - `history-ready` or `catalog-only`
  - `backtest-ready` or `backtest-paused`
  - `compare-ready` or `compare-paused`
  - `AI full-context` or `AI limited-context`
- The history/backtest readiness strip shows the same capability state for
  history-ready ETFs.
- Widget tests cover both history-ready and catalog-only selected ETF states.

## Data boundary

These badges are data-availability labels only. They do not change which ETF
histories are imported, which comparisons are allowed, or how backtests are
calculated.
