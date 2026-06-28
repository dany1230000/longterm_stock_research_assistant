# 00631L lab v6.26 overview date axis fit

v6.26 improves the overview chart date axis on phone-width screens.

## What changed

- Added horizontal edge padding to the overview one-year sparkline.
- Left, middle, and right date ticks now align to their edge positions instead of all being centered.
- Added stable widget keys for the start and end date ticks.

## Scope

- UI readability only.
- No historical price recalculation.
- No data-source or ETF import behavior changes.

## Validation

Run:

```cmd
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```
