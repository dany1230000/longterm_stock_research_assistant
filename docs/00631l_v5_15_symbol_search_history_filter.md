# 00631L v5.15 Symbol Search History Filter

v5.15 improves the left-top symbol search sheet with history-availability
filters.

## What Changed

- Added search filters:
  - `全部`
  - `歷史可用`
  - `catalog-only`
- The filter uses the same history-readiness logic as ETF result badges.
- The status strip shows the active filter.
- Widget tests verify that a catalog-only ETF disappears under `歷史可用` and
  appears again under `catalog-only`.

## Why It Matters

The app now has a broader ETF catalog and imported ETF price histories. The
filter helps users find symbols that can actually support history, backtest, and
comparison views before switching ETF context.

## Data Scope

- No new data source is added.
- The filter only changes visibility in the search sheet.
- Missing ETF histories remain labeled as catalog-only and are not treated as
  complete historical data.

## Safety

This release is a navigation and data-availability improvement. It does not add
investment guidance, forecasts, account integration, or automated actions.
