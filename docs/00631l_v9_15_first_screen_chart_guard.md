# 00631L lab v9.15 first-screen chart guard

v9.15 adds a focused UI guard for the mobile overview first screen.

## What changed

- The overview sparkline chart now has a stable widget key.
- The phone-width widget test verifies that the one-year chart remains visible
  within the first viewport.
- This keeps the home screen focused on the quote, source readiness, and trend
  chart instead of allowing future status blocks to push the chart too far down.

## Scope

- No data-source changes.
- No backtest calculation changes.
- No ETF universe changes.
- No trading or position guidance.

## Validation

- `flutter test test\etf_00631l_widget_test.dart --plain-name "00631L lab remains readable on phone width"`
