# 00631L v4.67 Public Batch Resume Status

v4.67 makes the public maintenance status aware of the local public ETF catalog
batch resume state.

## What Changed

- `scripts\00631l_public_maintenance_status.cmd` now reads the default
  `backend\data\00631l_public_etf_catalog_batch_state.json` state file when it
  exists.
- The maintenance summary includes:
  - `catalogBatchStateUpdatedAt`
  - `catalogBatchStateStatus`
  - `catalogBatchCatalogRowCount`
  - `catalogBatchFinalReadyCount`
  - `catalogBatchNextOffset`
  - `catalogBatchFailedOffset`
- The one-line command output also prints `nextOffset`.
- If resume state has a next offset or failed offset, action items point to:

```cmd
scripts\00631l_public_etf_catalog_batches.cmd --resume
```

## Daily Use

Check public maintenance status:

```cmd
scripts\00631l_public_maintenance_status.cmd --soft-fail
```

If ETF history is still below the expected floor and resume state exists, resume
catalog batches:

```cmd
scripts\00631l_public_etf_catalog_batches.cmd --resume --soft-fail
```

## Notes

- This script does not modify public backend data.
- Batch state is local runtime state and is not committed.
- A WARN is acceptable when public deployment is still catching up or ETF
  history is intentionally being imported in small batches.
