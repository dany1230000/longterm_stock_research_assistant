# 00631L Lab v9.13 Selected ETF Readiness

## Scope

This release makes the selected ETF overview shorter and clearer.

- Non-00631L ETFs now use the same compact quote readiness strip as 00631L.
- The old selected ETF core-data card is removed from the overview first screen.
- The selected ETF coverage range is shown directly under the quote card.
- The history/backtest page still keeps its own readiness strip for deeper checks.

## User Impact

After using the top-left symbol search, the selected ETF overview now shows:

1. Price source.
2. History row count and coverage.
3. Backtest readiness.
4. Intraday NAV scope.

This keeps the first screen compact while preserving source and coverage clarity.

## Limits

- Non-00631L holdings are not presented as official holdings.
- Intraday NAV remains live only where the backend source supports it.
- No investment instruction wording or automated trading behavior was added.
