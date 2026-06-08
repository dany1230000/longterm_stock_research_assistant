# 00631L lab v1.28 release summary

Completed on 2026-06-09.

## Scope

v1.28 polishes the `/00631l-lab` operations/status area with a compact "下一步操作提示" block.

The guidance is generated from `EtfOperationsStatus` and covers only app operation steps:

- daily cycle not yet recorded
- backend env missing
- intraday NAV unavailable
- CSV export missing
- local backup missing
- data/export/backup directory check needed

## UI behavior

The page keeps the existing status cards and adds a small text list below them. It does not add notification logic or new investment analysis.

## Constraints

- TX live remains mock/fallback by design.
- Scope remains 00631L only.
- Guidance only describes local app operation and data status.
- Mock/fallback data is not labeled as official.
