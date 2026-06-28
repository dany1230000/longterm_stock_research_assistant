# 00631L lab v6.14 symbol search filter counts

v6.14 makes the ETF/stock search sheet clearer when filter chips are used.

## What changed

- The search sheet now shows the filtered ETF count against the current
  candidate count when a search query is active.
- Added stable widget coverage for the `all`, `ready`, and `catalogOnly`
  search filters.
- The result count is display-only and does not change source data,
  eligibility rules, or selected ETF behavior.

## Data boundary

History-ready ETFs remain the only ETF rows eligible for history, backtest,
comparison, and AI performance context. Catalog-only rows are still visible so
the user can see that a symbol exists, but the app labels missing history
capabilities truthfully.
