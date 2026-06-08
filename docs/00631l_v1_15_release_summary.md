# 00631L Lab v1.15 Release Summary

Date: 2026-06-09

## Scope

v1.15 records the latest daily cycle result.

Added:

- `backend/scripts/run_00631l_daily_cycle.py`
- `scripts/00631l_daily_cycle.cmd` now delegates to the Python runner.
- The runner writes local ignored state to `backend/data/00631l_daily_cycle_status.json`.

Recorded fields:

- `startedAt`
- `finishedAt`
- `overallStatus`
- collect result
- export result
- smoke result
- warnings
- failures

`/api/etf/00631l/operations/status` reads the status file when present. If it is missing, the endpoint reports `sourceStatus: unavailable` and `overallStatus: missing`.

## Boundaries

This release does not connect TX live, expand beyond 00631L, add notification features, or add trading advice. The daily cycle result is an operational status record only.

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
