# 00631L lab v6.27 overview core strip

v6.27 reduces first-screen vertical weight in the overview page.

## What changed

- The overview core data metrics now render as a horizontal compact strip.
- The quote card and one-year chart appear sooner on phone screens.
- Other metric grids remain unchanged.

## Scope

- Mobile layout polish only.
- No source, history, backtest, or position calculation changes.
- No data-source relabeling.

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
