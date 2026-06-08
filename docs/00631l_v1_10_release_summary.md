# 00631L Lab v1.10 Release Summary

Date: 2026-06-08

## Scope

v1.10 adds an operations status endpoint and a matching frontend section so the lab can show whether daily collection is actually accumulating local history.

Added:

- `GET /api/etf/00631l/operations/status`
- `EtfOperationsStatus` frontend model.
- Proxy/mock/cached repository support for operations status.
- `/00631l-lab` section: `資料收集狀態`.

## Source Rules

The operations status endpoint reads local config and local JSONL history summaries. It does not fetch Yuanta/TWSE live sources and does not treat mock/fallback data as official operational state.

## UI

The section shows:

- local holdings history row count and latest trade date.
- intraday NAV sample count and latest data time.
- TWSE/Yuanta intraday URL configured/unset state.
- collector commands for daily and intraday collection.

## Boundaries

This release does not connect TX live, expand beyond 00631L, add push notifications, or add trading advice.

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
