# 00631L v4.69 Public Batch Timeout Payload

v4.69 hardens the public ETF catalog batch runner against remote timeout
exceptions.

## What Changed

- A timeout raised by the batch maintenance runner is converted into a normal
  JSON payload instead of a traceback.
- The failed offset is recorded in the local resume state file.
- `--soft-fail` can now return a payload even when the remote backend or TWSE
  read path times out.

## Daily Use

Run a small public batch with soft-fail:

```cmd
scripts\00631l_public_etf_catalog_batches.cmd --start-offset 15 --batch-size 10 --max-batches 1 --soft-fail
```

If it returns WARN or FAIL, check the printed `nextOffset` or use:

```cmd
scripts\00631l_public_maintenance_status.cmd --soft-fail
```

## Notes

- This does not hide failures. It records them as payload fields so the next run
  can continue from a known state.
- Public ETF history import still depends on public backend uptime and official
  source responsiveness.
