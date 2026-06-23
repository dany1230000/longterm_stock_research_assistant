# 00631L lab v5.1 - history chart touch detail

Completed: 2026-06-23

## Scope

This release improves the mobile readability of history charts without changing
data sources, TX live behavior, or ETF scope.

## Changes

- History and overview chart x-axis labels now use a clearer two-line format:
  `YYYY` and `MM/DD`.
- Line charts show the latest available date and value by default.
- Touching a chart switches the detail row to the selected date and value.
- The chart detail row is styled as a compact inline panel instead of a single
  low-visibility sentence.
- Widget tests now cover the clearer date labels and default latest-data detail.

## Data Notes

- Price history still uses split-adjusted close for performance and backtest
  calculations.
- Static public mode and live proxy mode are unchanged.
- This is a data display improvement only. It is not investment guidance.

## Validation

- `flutter analyze`
- `flutter test test\etf_00631l_widget_test.dart`
- Full release validation is required before tagging.
