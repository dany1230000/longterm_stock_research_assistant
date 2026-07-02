# 00631L v15.2 Overview Touch Detail Density

This release tightens the phone overview chart detail row.

## What Changed

- Chart tap details keep the selected date and value visible.
- Compact phone width uses smaller touch-detail pill padding.
- The overview chart stays expanded on the home screen.

## Product Boundary

- No price-history calculation change.
- No split-adjustment change.
- No backtest change.
- This is a phone layout density improvement only.

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
