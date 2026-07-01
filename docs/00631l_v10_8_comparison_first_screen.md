# 00631L lab v10.8 comparison first screen

## Goal

Make the ETF comparison section start with the controls users actually need:
choose ETFs, review the current basket, then open charts or checks when needed.

## Changes

- Moved the basket consistency explanation behind a `組合檢查` expansion.
- Kept comparison chips and quick preset filters visible.
- Kept the current basket summary visible.
- Kept the return chart and detailed table behind the existing chart expansion.
- Added widget coverage that verifies the basket check is hidden first and
  visible after expansion.

## Data Rules

- Comparison remains self-selected and does not force any ETF as a fixed
  baseline.
- Only ETF histories with enough verified rows are included.
- No data fetching, history calculation, or comparison metric logic changed.

## Verification

- `flutter test test\etf_00631l_widget_test.dart`
- Full release validation remains required before tagging.
