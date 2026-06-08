# 00631L Lab v1.17 Release Summary

Date: 2026-06-09

## Scope

v1.17 completes local CSV export metadata.

Holdings CSV includes:

- `tradeDate`
- `navPerUnit`
- `fundNetAssetValue`
- `outstandingUnits`
- `txWeightPct`
- `tsmcWeightPct`
- `stockExposurePct`
- `futuresExposurePct`
- `cashAndMarginPct`
- `sourceStatus`
- `sourceUrl`
- `fetchedAt`
- `sourceHash`

Export metadata:

- `exportedAt`
- holdings row count
- intraday row count
- total row count
- source history range
- output paths

Generated files remain under ignored local output:

```text
backend/exports/
```

## Boundaries

This release does not connect TX live, expand beyond 00631L, add notification features, or add trading advice. Export reads local history only.

## Validation

Required validation:

```cmd
scripts\00631l_check_env.cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_daily_cycle.cmd
scripts\00631l_export_history.cmd
py backend\scripts\smoke_00631l_live.py
git diff --check
```
