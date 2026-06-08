# 00631L Lab v1.16 Release Summary

Date: 2026-06-09

## Scope

v1.16 polishes the daily holdings history view.

Added:

- recent 7-row holdings summary cards
- day-over-day change
- first-to-latest change
- trend-summary model helper for holdings history metrics
- tests for history change calculation and widget rendering

Displayed metrics:

- TX weight
- TSMC weight
- stock asset %
- futures asset %
- cash/margin %
- NAV
- outstanding units

## Boundaries

This release does not connect TX live, expand beyond 00631L, add notification features, or add trading advice. The history view only describes official/cached local holdings history changes.

## Validation

Required validation:

```cmd
scripts\00631l_check_env.cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_daily_cycle.cmd
py backend\scripts\smoke_00631l_live.py
git diff --check
```
