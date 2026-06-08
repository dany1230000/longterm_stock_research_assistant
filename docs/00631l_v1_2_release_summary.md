# 00631L Lab v1.2 Release Summary

Date: 2026-06-08

## Scope

v1.2 adds daily holdings history for the 00631L lab. The backend stores successful Yuanta 00631L ratio official snapshots in a local JSONL file and exposes history endpoints for the Flutter app.

This release does not connect TX live, does not expand to all leveraged ETFs, and does not provide trading instructions.

## Storage

Default path:

```text
backend/data/00631l_holdings_history.jsonl
```

The path can be changed with:

```text
00631L_HOLDINGS_HISTORY_PATH
```

Records are deduplicated by `tradeDate`. Re-fetching the same `tradeDate` and `sourceHash` does not append a duplicate. If the same `tradeDate` has a new `sourceHash`, the stored row is replaced.

## Endpoints

```text
GET /api/etf/00631l/holdings/history?limit=30
GET /api/etf/00631l/holdings/history/summary?limit=30
```

The summary endpoint returns trend fields for the app:

- `tradeDate`
- `txWeightPct`
- `tsmcWeightPct`
- `stockExposurePct`
- `futuresExposurePct`
- `cashAndMarginPct`
- `navPerUnit`
- `fundNetAssetValue`
- `outstandingUnits`

## Frontend

`/00631l-lab` includes a "每日內容物歷史" section. It renders a table when history exists and "尚無歷史紀錄" when no local history is available.

Mock/fallback data is never labeled as official history.

## Validation

Run before release:

```powershell
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
py backend\scripts\smoke_00631l_live.py
git diff --check
```
