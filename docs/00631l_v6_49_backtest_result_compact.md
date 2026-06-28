# 00631L v6.49 backtest result compact

v6.49 makes the history/backtest page shorter on phones.

## What changed

- The top backtest quick result strip now includes annualized return and volatility.
- The duplicated 2x2 result card grid below the input panel was removed.
- Equity and drawdown charts remain visible below the compact settings area.

## Data behavior

- Backtest formulas, date ranges, transaction-cost input, and price-history sources did not change.
- The page still shows that backtests are historical calculations, not future performance.
- No live TX connection, ETF universe expansion, or investment instruction was added.

## Validation focus

- Widget coverage verifies the compact quick result strip is present.
- Existing history/backtest tests still cover date range controls, cost input expansion, and non-advice wording.
