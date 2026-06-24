# 00631L v5.5 History / Backtest Range Context

Release tag: `00631l-lab-v5.5-history-backtest-range-context`

## What Changed

- Added a compact range context strip to the history price chart section.
- Added the same range context strip to the backtest section.
- Kept the default history and backtest range at the latest 1 year.
- Kept manual start/end date controls visible before the chart and backtest result.
- Preserved chart tap detail: charts still show the latest date/value by default and exact date/value after touch.

## User Impact

- The history page now states the active date range, row count, full row count, and latest data date in one grouped area.
- The backtest page now states the active date range, strategy, sample count, and cost setting before the input fields and result cards.
- This is a layout and clarity release only. It does not add trading instructions or future forecasts.

## Data Notes

- Price history uses split-adjusted close when available.
- Backtest output uses only saved historical price rows inside the selected date range.
- Backtest results do not represent future performance and are not investment guidance.

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
