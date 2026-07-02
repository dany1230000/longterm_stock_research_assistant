# 00631L v14.9 History Chart Density

This release removes excess empty space from the mobile history chart cards.

## What Changed

- Compact phone width now renders mini chart cards as a content-sized vertical list.
- Desktop and wider layouts keep the two-column chart grid.
- Chart cards no longer reserve a fixed grid height on phones after the touch detail row.

## Product Boundary

- No historical calculation change.
- No backtest calculation change.
- No data-source change.
- This is a mobile layout density fix for history charts.

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
