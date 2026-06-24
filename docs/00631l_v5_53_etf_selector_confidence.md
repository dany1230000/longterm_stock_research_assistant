# 00631L lab v5.53 ETF selector confidence

v5.53 makes the top-left ETF selector more explicit about what each ETF can do
after switching.

## Changes

- Search results now show compact capability badges for imported history,
  backtest readiness, comparison readiness, AI context, and live NAV scope.
- Catalog-only ETFs now show `history missing`, `backtest unavailable`, and
  limited AI context labels before the user switches.
- Non-00631L rows clearly state that live NAV remains scoped to 00631L unless a
  future source is added.

## Why

The selector is becoming the entry point for the ETF research room. Users should
know whether a symbol supports history, backtesting, comparison, and AI context
before changing the current ETF.

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
