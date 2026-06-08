# 00631L Lab v1.25 Release Summary

Date: 2026-06-09

## Scope

v1.25 adds local data directory health checks.

Updated:

- `scripts/00631l_check_env.cmd`
- `/api/etf/00631l/operations/status`
- `/00631l-lab` operations/status display
- backend endpoint tests
- frontend repository/widget tests

The check covers:

- `backend/data`
- `backend/exports`
- `backend/backups`
- directory write access
- recent holdings history presence
- recent export metadata presence
- recent backup archive presence

Missing local data on a fresh install is WARN, not FAIL.

## Boundaries

This release does not connect TX live, expand beyond 00631L, add notification features, or add trading advice.

## Validation

Required validation:

```cmd
scripts\00631l_check_env.cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```
