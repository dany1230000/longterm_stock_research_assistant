# 00631L lab v10.6 search result cleanup

## Goal

Make the left-top ETF search feel like a clean app picker instead of a dense
debug list.

## Changes

- ETF result rows now prioritize:
  - ETF code and display name
  - latest visible price
  - history/backtest readiness
  - row-count metadata when available
- Price-basis, split-adjustment, and missing-history details moved into the
  same row's `更多資料` expansion.
- Catalog-only ETF rows still explain why history/backtest is unavailable after
  expansion.
- Selecting an ETF still switches the whole lab context.

## Data Rules

- Readiness labels remain truthful.
- Missing history is never treated as official historical data.
- Split-adjustment information remains available for verification.
- No search, price, or history import logic changed in this release.

## Verification

- `flutter test test\etf_00631l_widget_test.dart`
- Full release validation remains required before tagging.
