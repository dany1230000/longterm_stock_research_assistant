# 00631L v4.64 Public Catalog Batch Resume

Release goal: make public ETF catalog history maintenance resumable after a hosted backend timeout, restart, or transient HTTP error.

## What Changed

- `scripts\00631l_public_etf_catalog_batches.cmd` now writes a local resume state file after non-dry-run execution.
- Default state path:
  - `backend\data\00631l_public_etf_catalog_batch_state.json`
- The state records:
  - `overallStatus`
  - `plannedOffsets`
  - `nextOffset`
  - `failedOffset`
  - `finalReadyCount`
  - warnings, failures, and action items
- New CLI options:
  - `--resume`
  - `--state-path <path>`

## Usage

```cmd
scripts\00631l_public_etf_catalog_batches.cmd --batch-size 10 --max-batches 1 --soft-fail
scripts\00631l_public_etf_catalog_batches.cmd --resume --batch-size 10 --max-batches 1 --soft-fail
```

If the previous batch failed, `--resume` starts from the failed offset stored in `nextOffset`. If the previous batch completed cleanly, it starts from the next planned offset.

## Repository Safety

The resume state lives under `backend\data`, which is ignored. It must not be committed.
