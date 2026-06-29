# 00631L lab v9.17 selected ETF price context

v9.17 makes selected-ETF data correctness visible earlier.

## What changed

- After switching ETF from the top-left search, the quote header now shows:
  - history coverage range
  - price field used by history/backtest
  - split-adjustment confidence
- Existing history quality panels remain available for deeper detail.
- Widget tests verify that the selected-ETF header exposes price-field and
  split-adjustment context.

## Scope

- No new data source was added.
- No ETF comparison behavior was changed.
- No backtest calculation behavior was changed.
- No trading or position guidance was added.

## Validation

- `flutter test test\etf_00631l_widget_test.dart --plain-name "selecting ETF switches overview position and AI context"`
- `flutter test test\etf_00631l_widget_test.dart --plain-name "selected ETF history distinguishes close-mirrored adjustment"`
