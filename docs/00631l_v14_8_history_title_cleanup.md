# 00631L v14.8 History Title Cleanup

This release cleans up the history/backtest page title strip.

## What Changed

- The history top strip no longer repeats the ETF code when the source name is the same as the code.
- `00631L 00631L` is reduced to one clear `00631L` title.
- The source badge, row count, latest value, and adjustment context remain visible.

## Product Boundary

- No historical data calculation change.
- No backtest calculation change.
- No data-source change.
- This is a history page label and information hierarchy cleanup only.

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
