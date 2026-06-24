# 00631L lab v5.33 overview chart priority

## Scope

v5.33 makes the mobile overview easier to scan by moving the price chart directly
under the quote header. The user sees the current symbol, price context, and
recent trend before secondary data-quality strips.

## Changes

- Moved the overview chart block above data-quality and update-time strips.
- Kept the chart expanded by default.
- Kept data-quality and update-time information visible below the chart.
- Added a widget test that verifies the chart appears before the data-quality
  strip.

## Data Notes

This release changes layout only. It does not change ETF data sourcing,
historical price calculations, TX quote sourcing, or source-status labels.

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
