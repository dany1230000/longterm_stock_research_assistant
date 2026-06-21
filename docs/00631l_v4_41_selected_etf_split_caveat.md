# ETF research room v4.41 selected ETF split caveat

v4.41 surfaces split-adjustment status in the selected ETF AI context.

## What Changed

- The selected ETF AI page now shows the price field used for analysis.
- The same summary now states whether split adjustment is detected, available through adjusted prices, or not applied.
- The wording explicitly tells users to confirm `adjustmentFactor` when an ETF has known split events.

## Why

Historical analysis and backtests are only as reliable as the loaded price field. The app should not imply that every ETF history is split-adjusted when only the loaded data can prove it.

## Scope

- UI wording and widget coverage only.
- Does not alter price-history import, backtest math, TX live, or investment guidance.
