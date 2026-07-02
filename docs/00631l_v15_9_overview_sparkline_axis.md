# 00631L v15.9 Overview Sparkline Axis

This release improves the phone overview chart density.

## What Changed

- Phone overview sparkline now shows the selected date and price above the chart.
- Compact date axis now shows only the start and end dates.
- Desktop and wider layouts still keep the richer three-point date axis.

## Product Boundary

- No data source change.
- No backtest or holdings logic change.
- No trading instruction or forecast logic.

## Validation

Run the normal release checks:

```cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```
