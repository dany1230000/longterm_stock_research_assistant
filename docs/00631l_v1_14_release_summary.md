# 00631L Lab v1.14 Release Summary

Date: 2026-06-09

## Scope

v1.14 adds a data freshness summary for daily operation.

Backend additions:

- `/api/etf/00631l/operations/status` reports env readiness, latest holdings history date, latest intraday NAV data time, history counts, CSV export availability, and latest daily cycle status when a local status file exists.
- The endpoint reads local state only. It does not fetch live sources.
- Missing local state is reported as `unavailable` or `error`, not `official`.

Frontend additions:

- `/00631l-lab` shows "今日資料狀態".
- The section displays holdings status, intraday NAV status, history counts, export status, daily cycle status, env readiness, fallback configuration, and local data directory readiness.

## Boundaries

This release does not connect TX live, expand beyond 00631L, add notification features, or add trading advice. The summary only describes data freshness and operational status.

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
