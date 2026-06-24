# 00631L Lab v5.21 Custom ETF Comparison Basket

## Completed Scope

- The history/backtest comparison panel now starts from the active ETF's peer
  group instead of always defaulting to the active symbol only.
- Users can clear the comparison basket, apply the active ETF's peer preset, or
  view only the active ETF.
- The basket remains limited to 1-5 selected ETFs for readable mobile charts.
- Selecting a non-00631L ETF no longer implies every comparison is anchored to
  00631L.

## Data Behavior

- The comparison still uses imported ETF price history only.
- Static-public data remains available for GitHub Pages.
- Live intraday NAV still requires the backend proxy.
- Missing ETF history stays visible as a data-readiness issue and is not filled
  with mock official data.

## User-Facing Boundaries

- The comparison describes historical data only.
- It is not a recommendation engine.
- It does not add TX live behavior, all-stock coverage, alerts, or automated
  actions.
