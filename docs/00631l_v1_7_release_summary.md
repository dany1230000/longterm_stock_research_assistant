# 00631L Lab v1.7 Release Summary

Date: 2026-06-08

## Scope

v1.7 adds a backend snapshot collector so daily holdings history and intraday NAV history can accumulate without requiring the Flutter page to be open.

Added:

- `backend/app/collector.py`: collection helper that summarizes profile, holdings, intraday NAV, and local history state.
- `backend/scripts/collect_00631l_snapshot.py`: manual/Task Scheduler friendly Python collector.
- `scripts/00631l_collect_snapshot.cmd`: CMD wrapper for Windows environments where PowerShell script execution is disabled.
- `backend/tests/test_collector.py`: unit tests for collector PASS/WARN/FAIL behavior.

## Usage

One-shot daily collection:

```cmd
scripts\00631l_collect_snapshot.cmd --samples 1
```

Intraday sample collection:

```cmd
scripts\00631l_collect_snapshot.cmd --skip-profile --skip-holdings --samples 20 --interval-seconds 15
```

## Source Rules

Successful official Yuanta holdings snapshots are persisted to `00631L_HOLDINGS_HISTORY_PATH`. Successful official TWSE/Yuanta intraday NAV samples are persisted to `00631L_INTRADAY_NAV_HISTORY_PATH`.

Mock, unavailable, error, or stale fallback data is not labeled as official and is not used as official history.

## Boundaries

This release does not connect TX live, expand beyond 00631L, add push notifications, or add trading advice.

## Validation

Run before tagging:

```powershell
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_collect_snapshot.cmd --samples 1
scripts\00631l_daily_smoke.cmd --no-env-file
git diff --check
```
