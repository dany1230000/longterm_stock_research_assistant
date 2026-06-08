# 00631L Lab v1.12 Release Summary

Date: 2026-06-08

## Scope

v1.12 adds a one-command daily cycle for local operation.

Added:

- `scripts/00631l_daily_cycle.cmd`

The cycle runs:

1. `scripts\00631l_collect_snapshot.cmd --samples 1`
2. `scripts\00631l_export_history.cmd`
3. `scripts\00631l_daily_smoke.cmd`

## Source Rules

The cycle uses the existing collector, exporter, and smoke scripts. It does not add new data sources, does not connect TX live, and does not change parser behavior.

## Boundaries

This release does not expand beyond 00631L and does not add trading advice.

## Validation

Run before tagging:

```cmd
scripts\00631l_daily_cycle.cmd
```

Also run the standard validation sequence:

```powershell
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
git diff --check
```
