# 00631L Lab v5.19 ETF Data Readiness Ratio

## Scope

v5.19 improves the Settings data-library section for multi-ETF readiness.

## What Changed

- Adds a completion metric for ETF price-history readiness.
- Uses `ready / total` operations status to calculate the ratio.
- Keeps the existing catalog count, long-term tier, recent tier, not-ready
  count, and data-time cards.
- Makes it easier to verify whether the ETF data library is suitable for symbol
  switching, backtests, and comparisons.

## User Impact

Users can see how complete the ETF history dataset is before selecting other
ETFs. If the ratio is low, the next program operation is to run the existing ETF
price-history import script.

This is a data coverage indicator only.

## Validation

- `flutter analyze`
- `flutter test`
- `flutter build web`
- `py -m unittest discover -s backend\tests`
- `scripts\00631l_release_check.cmd`
- `git diff --check`
