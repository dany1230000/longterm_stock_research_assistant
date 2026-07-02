# 00631L v14.5 Comparison Guidance Density

This release tightens the ETF comparison area inside the history/backtest page.

## What Changed

- The selected-basket compact summary is now the main comparison status line.
- Repeated guidance, mode summary, and selected-code text blocks were removed from the main flow.
- ETF selection, quick peer presets, readiness checks, basket inspection, and comparison chart expansion remain available.

## Product Boundary

- No comparison calculation change.
- No ETF universe change.
- No data-source change.
- The comparison remains historical data inspection, not investment guidance.

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
