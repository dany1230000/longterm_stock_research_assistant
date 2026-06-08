# 00631L Lab v1.9 Release Summary

Date: 2026-06-08

## Scope

v1.9 improves the intraday premium/discount history section with a compact trend chart.

Added:

- premiumDiscountPct intraday trend line.
- 0% reference line.
- Time labels and a compact legend.

## Source Rules

The chart uses stored official intraday NAV history from the backend proxy. It does not fetch a new source, does not infer official data from mock/fallback rows, and does not connect TX live.

## Boundaries

This release does not add trading signals, push notifications, all-leveraged-ETF support, or buy/sell advice.

## Validation

Run before tagging:

```powershell
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_daily_smoke.cmd --no-env-file
git diff --check
```
