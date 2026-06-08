# 00631L Lab v1.8 Release Summary

Date: 2026-06-08

## Scope

v1.8 improves the daily holdings history section with a compact trend chart.

Added:

- TX weight trend.
- TSMC weight trend.
- Cash and margin weight trend.
- Legend and axis labels that work with the existing table view.

## Source Rules

The chart uses the same normalized holdings history summary as the table. It does not fetch new data, does not connect TX live, and does not create official history from mock/fallback data.

## Boundaries

This release does not add trading signals, push notifications, all-leveraged-ETF support, or TX live quotes.

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
