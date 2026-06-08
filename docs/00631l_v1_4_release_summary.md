# 00631L Lab v1.4 Release Summary

Date: 2026-06-08

## Scope

v1.4 adds intraday NAV and premium/discount history for 00631L.

When the backend successfully fetches an official TWSE or Yuanta intraday NAV sample, it saves the sample locally in JSONL. The frontend shows today's highest premium, lowest discount, average premium/discount, last sample time, and recent samples.

This release does not connect TX live, does not add push notifications, and does not add trading signals.

## Storage

Default path:

```text
backend/data/00631l_intraday_nav_history.jsonl
```

The path can be changed with:

```text
00631L_INTRADAY_NAV_HISTORY_PATH
```

Samples are deduplicated by `sourceContract` and `dataTime`.

## Endpoints

```text
GET /api/etf/00631l/intraday-nav/history?date=YYYY-MM-DD&limit=500
GET /api/etf/00631l/intraday-nav/history/summary?date=YYYY-MM-DD
```

The summary endpoint returns:

- `sampleCount`
- `highestPremiumDiscountPct`
- `lowestPremiumDiscountPct`
- `averagePremiumDiscountPct`
- `firstDataTime`
- `lastDataTime`
- `latestMarketPrice`
- `latestEstimatedNav`

## Frontend

`/00631l-lab` includes a "盤中折溢價歷史" section. If no local intraday samples exist, it shows "尚無盤中折溢價歷史" and keeps source status visible.

Mock/fallback data is never labeled as official intraday history.

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
