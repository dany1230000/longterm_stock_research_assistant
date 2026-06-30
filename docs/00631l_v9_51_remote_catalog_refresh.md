# 00631L lab v9.51 - remote catalog refresh

Date: 2026-06-30

## Goal

Keep the public backend ETF universe aligned with the current TWSE ETF catalog
during daily remote maintenance.

## Change

- `scripts\00631l_remote_maintenance.cmd --mode daily` now calls
  `POST /api/etf/catalog/import` before price-history maintenance.
- The catalog import step is summarized in remote maintenance output with
  `sourceStatus`, `rowCount`, `dataTime`, and `outputPath`.
- If catalog import is unavailable or returns no rows, daily maintenance reports
  WARN and continues with the existing cached or seed catalog.

## Why

Public backend data can lag GitHub Pages static data when the persistent catalog
file is older than the static export. Refreshing the catalog as part of daily
maintenance lets later ETF history batches operate on the latest backend ETF
universe.

## Scope

This release updates maintenance orchestration only. It does not change ETF
selection rules, TX live sourcing, notification behavior, automated actions, or
investment guidance.
