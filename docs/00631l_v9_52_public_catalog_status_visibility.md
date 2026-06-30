# 00631L lab v9.52 - public catalog status visibility

Date: 2026-06-30

## Goal

Make public backend ETF catalog completeness visible in the standard status and
freshness checks.

## Change

- `scripts\00631l_public_backend_status.cmd` now checks
  `GET /api/etf/catalog/status`.
- Public backend status now reports:
  - catalog row count
  - catalog source status and data time
  - ETF history ready count
  - catalog/history gap count
- A new `catalog_history_alignment` check warns when the public ETF catalog has
  more rows than saved ETF price histories.
- `scripts\00631l_compare_public_freshness.cmd` now includes public/static
  catalog counts and a direct action item for catalog history gaps.

## Why

After a catalog refresh, public backend history can be missing one newly listed
ETF even while 00631L price history is fresh. The status scripts should show
that gap directly instead of requiring manual `/api/etf/history/gaps` queries.

## Scope

This release only improves deployment and data-maintenance visibility. It does
not connect TX live data, expand trading features, add notifications, or provide
investment guidance.
