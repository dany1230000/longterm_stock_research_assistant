# 00631L v15.12 Header Scale

This release adjusts the phone app header proportions.

## What Changed

- The top app bar is slightly taller.
- `ETF 研究室` uses a larger title size.
- The selected ETF subtitle is slightly easier to read.
- The left symbol search pill remains compact and tappable.

## Product Boundary

- No navigation change.
- No data source change.
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
