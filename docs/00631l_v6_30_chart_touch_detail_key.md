# 00631L lab v6.30 chart touch detail key

v6.30 adds a stable test hook for chart touch-detail panels.

## What changed

- `_ChartTouchDetail` now exposes `00631l-line-chart-touch-detail`.
- Widget coverage verifies the history page renders chart touch-detail panels.
- This prepares the history/backtest chart UI for safer follow-up date-label and
  tap-detail polish without relying on fragile text matching.

## Scope

- Testability and UI hook only.
- No price, history, backtest, or comparison calculation changes.
- No source-label changes.

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
