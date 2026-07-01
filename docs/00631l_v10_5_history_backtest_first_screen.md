# 00631L lab v10.5 history/backtest first screen

## Goal

Make the history/backtest page feel less like a long report and more like a
mobile tool screen.

## Changes

- Replaced the large repeated price-history section header with a compact
  heading.
- Added a small metric row to the history top strip:
  - latest data date and close
  - row count
  - source status
  - adjustment status
- Kept the default range at latest one year.
- Kept date controls directly above the charts and backtest context.
- Kept data-quality details inside an expansion panel.

## Data Rules

- No price, split, or backtest calculation logic changed.
- Split-adjusted price status remains visible.
- Static, proxy, mock, and unavailable labels remain truthful.
- Backtest output remains historical only and is marked as non-advisory.

## Verification

- `flutter test test\etf_00631l_widget_test.dart`
- Full release validation remains required before tagging.
