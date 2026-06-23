# 00631L lab v4.89 public storage path diagnostics

Release goal: make public backend persistence problems visible before more ETF history batches run.

## What changed

- `/ready` now includes a `storage_paths` check.
- `operations/status` now reports `dataDirectoryHealth.storagePaths`.
- The check covers the actual write targets used by:
  - holdings history
  - intraday NAV history
  - 00631L price history
  - ETF catalog cache
  - multi-ETF price history cache
  - daily cycle status
  - integrity status
  - restore dry-run status
  - CSV exports
  - backups
  - daily reports

## Why it matters

The public backend can have a writable root data directory but still write ETF history to a path that is not on the persistent volume. v4.89 exposes each effective path, whether it is writable, and whether required paths are under `00631L_DATA_DIR` when persistent mode is enabled.

## Expected public setup

Use a mounted persistent path such as:

```text
00631L_DATA_DIR=/data/00631l
00631L_DATA_PERSISTENCE_MODE=persistent
ETF_PRICE_HISTORY_DIR=/data/00631l/etf_price_history
ETF_CATALOG_PATH=/data/00631l/twse_etf_catalog.json
00631L_HISTORY_EXPORT_DIR=/data/00631l/exports
00631L_BACKUP_DIR=/data/00631l/backups
00631L_REPORT_DIR=/data/00631l/reports
```

If `storage_paths` is `WARN` or `FAIL`, fix the backend volume/env first. Do not continue public ETF catalog batches until the persistent path checks are healthy.
