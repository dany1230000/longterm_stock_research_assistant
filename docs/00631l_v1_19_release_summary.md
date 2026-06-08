# 00631L Lab v1.19 Release Summary

Date: 2026-06-09

## Scope

v1.19 documents the daily-use workflow for the 00631L lab.

Added:

- `docs/00631l_daily_usage.md`

Updated:

- `README.md`
- `backend/README.md`

The daily guide covers first-time setup, backend startup, Flutter live proxy startup, daily cycle, operations/status, holdings history, CSV export, smoke WARN review, backend-down handling, `.env` setup, source-status definitions, TX live scope, and the no-advice boundary.

## Boundaries

This release is documentation only. It does not connect TX live, expand beyond 00631L, add notification features, change parsers, or add trading advice.

## Validation

Required validation:

```cmd
scripts\00631l_release_check.cmd
```
