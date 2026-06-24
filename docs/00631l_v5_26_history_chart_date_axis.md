# 00631L lab v5.26 history chart date axis

## Scope

v5.26 improves date readability in the history and backtest charts. It does not change historical data ingestion, split adjustment, backtest formulas, or source status labels.

## UI changes

- Each compact history chart now shows a full-date axis strip below the chart.
- The strip labels the visible start, middle, and end dates as `起`, `中`, and `迄`.
- Existing chart touch detail remains available, so tapping the chart still shows the selected date and value.

## Data behavior

- History still defaults to the latest one-year range.
- Users can still change the range with start/end date buttons or quick range chips.
- Backtest output continues to state that historical results do not represent future performance and are not investment guidance.

## Validation

Run:

```cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```
