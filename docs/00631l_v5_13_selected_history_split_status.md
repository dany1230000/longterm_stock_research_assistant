# 00631L v5.13 Selected History Split Status

v5.13 makes the selected ETF history-quality card clearer about split-adjusted
price data.

## What Changed

- The history/backtest quality card now uses the label `分割調整` instead of the
  broader `調整價狀態`.
- The UI distinguishes:
  - `已套用分割調整` when a non-unit adjustment factor is present.
  - `調整價可用` when adjusted prices are available but no non-unit adjustment is
    present in the loaded history.
  - `未套用` when no adjusted price field is available.
- The widget fixture for selected ETF history now includes `adjustedClose` and
  `adjustmentFactor: 1.0`, matching the imported ETF history pipeline.

## Why It Matters

Backtest and performance views should make it obvious whether returns use a
split-aware price field. This release improves that visibility without changing
data sources or calculations.

## Safety

This release only clarifies data-quality labeling. It does not add investment
guidance, forecasting, automated actions, or account integration.
