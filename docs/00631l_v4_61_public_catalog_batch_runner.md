# 00631L v4.61 Public Catalog Batch Runner

Release goal: make broad public-backend ETF history maintenance a single command instead of manually running one offset at a time.

## What Changed

- Added `backend/scripts/run_public_etf_catalog_batches_00631l.py`.
- Added `scripts\00631l_public_etf_catalog_batches.cmd`.
- The runner:
  - reads `/api/etf/catalog/status`
  - plans offsets from the catalog row count
  - runs catalog history batches with `fromCatalog=true`
  - reads `/api/etf/history/status` after the batch run
  - reports `finalReadyCount`, warnings, failures, and next action items

## Usage

```cmd
scripts\00631l_public_etf_catalog_batches.cmd --dry-run --batch-size 10 --max-batches 8
scripts\00631l_public_etf_catalog_batches.cmd --batch-size 10 --max-batches 8 --soft-fail
```

If the public backend has not deployed the catalog seed fallback yet, this command returns `WARN` and tells the operator to check `/api/etf/catalog/status`.

The default batch size is intentionally small because hosted backends can time out while fetching many TWSE symbols in one request. If a batch times out but the final ready count increases, the runner reports `WARN` with partial progress instead of hiding that data was saved.

If a batch fails with an HTTP error, retry the same `--start-offset` shown in `actionItems`. Do not skip to the next offset until the failed batch is either saved or the final ready count confirms progress.

## Data Labels

The runner does not change source labels. If the backend uses `ETF_CATALOG_SEED_PATH`, catalog data is still labeled `static_official` until a local persistent catalog is imported.
