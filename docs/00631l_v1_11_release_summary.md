# 00631L Lab v1.11 Release Summary

Date: 2026-06-08

## Scope

v1.11 adds CSV export for local 00631L history stores.

Added:

- `backend/app/history_export.py`
- `backend/scripts/export_00631l_history.py`
- `scripts/00631l_export_history.cmd`
- `backend/tests/test_history_export.py`
- `backend/exports/` git ignore rule.

## Usage

```cmd
scripts\00631l_export_history.cmd
```

Default outputs:

- `backend/exports/00631l_holdings_history_summary.csv`
- `backend/exports/00631l_intraday_nav_history.csv`

## Source Rules

The exporter only reads existing local JSONL history. It does not fetch Yuanta/TWSE live sources and does not fabricate official records from mock/fallback data.

## Boundaries

This release does not connect TX live, expand beyond 00631L, add push notifications, or add trading advice.

## Validation

Run before tagging:

```powershell
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_export_history.cmd
git diff --check
```
