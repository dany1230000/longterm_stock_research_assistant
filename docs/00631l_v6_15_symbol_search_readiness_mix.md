# 00631L lab v6.15 symbol search readiness mix

v6.15 makes the top-left ETF search sheet clearer before switching symbols.

## What changed

- The search sheet now shows the current query's `history-ready` and
  `catalog-only` counts.
- This summary appears alongside the existing filter chips, so users can see
  the data availability mix without toggling each filter first.
- Added widget coverage for catalog-only search results and readiness-count
  keys.

## Data boundary

The readiness mix is informational.

Only history-ready ETFs are eligible for history, backtest, comparison, and AI
performance context. Catalog-only rows remain visible as catalog evidence and
are labeled separately.
