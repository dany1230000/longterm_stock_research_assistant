# 00631L v15.4 Backtest Result Density

This release tightens the backtest quick result strip on phones.

## What Changed

- Phone width hides the technical source badge inside the quick result strip.
- Strategy context and the non-advice label remain visible.
- Annualized return and volatility stay in the same compact result row.

## Product Boundary

- No backtest calculation change.
- No historical data source change.
- No strategy recommendation change.
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
