# 00631L lab v6.20 symbol search ranking

v6.20 improves the top-left ETF/stock search ordering.

## What changed

- ETF search results are ranked before display.
- Exact ETF code matches come first.
- ETF code prefix and code-contains matches come before name-only matches.
- For equal match quality, history-ready ETFs are shown before catalog-only
  ETFs.
- The search sheet exposes hidden rank keys for the first few rows so widget
  tests can verify ordering without depending on lazy list rendering.

## Why this matters

The ETF research room now has many catalog rows. A symbol-like query should show
the most likely code match first, while still keeping data readiness labels
truthful. Catalog-only rows remain visible, but they are not presented as ready
for history, backtest, comparison, or full AI context.
