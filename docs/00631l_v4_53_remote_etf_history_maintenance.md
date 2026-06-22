# 00631L v4.53 Remote ETF History Maintenance

## Scope

v4.53 extends public backend remote maintenance so daily maintenance also checks and updates the selected ETF basket price-history store.

This release does not change trading behavior, broker integration, or app product scope. It only improves data maintenance for the ETF research room.

## What Changed

- `backend/scripts/remote_maintenance_00631l.py` now includes:
  - `POST /api/etf/history/update`
  - `GET /api/etf/history/status`
- `daily` mode and `all` mode both include the new ETF history maintenance steps.
- The update step reads status after the update so logs include:
  - `readyCount`
  - `rowCount`
  - `coverageTierCounts`
  - `validationFailureCount`
  - `validationWarningCount`
  - `sourceUpdatedAt`
- If the public backend has an empty persistent volume, v4.52 seed fallback still makes selected ETF histories readable while daily maintenance fills local cache rows over time.

## Status Rules

- HTTP errors are `FAIL`.
- No ready ETF history rows are `WARN`.
- ETF history validation failures are `WARN`.
- Source timeout or unavailable status is `WARN` unless the endpoint itself fails.

Warnings are intentional here because the public backend should keep running when an official source is temporarily unavailable.

## Commands

Dry run:

```cmd
scripts\00631l_remote_maintenance.cmd --dry-run
```

Daily maintenance:

```cmd
scripts\00631l_remote_maintenance.cmd --mode daily
```

Full maintenance:

```cmd
scripts\00631l_remote_maintenance.cmd --mode all
```

Local ETF history status:

```cmd
scripts\00631l_import_etf_price_history.cmd --status-only --summary-only
```

## Verification

v4.53 adds backend tests for:

- planned remote maintenance endpoints
- daily multi-ETF history update/status execution
- warning behavior when ETF history has no ready rows
