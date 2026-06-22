# ETF research room v4.46 backtest range chips

Date: 2026-06-22

## Scope

v4.46 makes backtest date control faster on mobile.

## Changes

- The backtest block now has its own quick range chips: `最近 1 年`, `最近 3 年`, and `全部資料`.
- The existing start/end date buttons remain available for precise custom ranges.
- The default backtest range remains the latest one-year window.
- This change only affects UI range selection. It does not change the backtest engine, price source, split adjustment, or result formulas.

## Verification

- Widget coverage verifies the backtest quick range row exists.
- Widget coverage taps `全部資料` and verifies the backtest interval expands to the loaded coverage.
- Existing historical chart range controls remain separate from the backtest range controls.
