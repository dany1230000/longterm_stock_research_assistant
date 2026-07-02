# 00631L v15.11 Compact Chart Touch Detail

This release improves phone chart readability.

## What Changed

- Compact chart touch details now show only the selected date and value.
- Longer helper text remains available on wider layouts.
- The overview chart no longer truncates helper text beside the key numbers.

## Product Boundary

- No chart data change.
- No backtest logic change.
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
