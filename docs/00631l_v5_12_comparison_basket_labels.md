# 00631L v5.12 Comparison Basket Labels

v5.12 polishes the ETF history comparison section so it reads like a
user-selected basket instead of a fixed comparison against 00631L.

## What Changed

- The history/backtest comparison header now says users can build a 1-5 ETF
  comparison basket.
- The selected comparison label now reads `目前 basket：...`.
- The quick filter guidance clarifies that category filters are only shortcuts;
  users can still adjust the selected ETF chips manually.
- Widget tests cover the updated basket wording and selected-code label.

## Data Scope

- No new data source is added in this release.
- Static public and live proxy history sources continue to work as before.
- 00631L remains the only ETF with complete official daily holdings and live
  intraday NAV context in this app.

## Safety

The comparison section describes historical data only. It does not provide
investment guidance, future forecasts, automated actions, or account
integration.
