# 00631L lab v5.54 comparison basket context

v5.54 makes ETF comparison read like a user-selected basket instead of a fixed
benchmark view.

## Changes

- The history/backtest comparison area now shows a compact basket data check.
- The check lists selected ETF codes, common coverage range, minimum row count,
  and source status labels.
- Empty selection now explicitly reports `basket empty` before the chart area.
- The copy states that the chart uses the selected basket and does not set any
  ETF as a fixed benchmark.

## Why

ETF comparison should be controlled by the user-selected basket. The UI now
shows whether the chosen ETF group has enough overlapping history before the
chart and table are interpreted.

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
