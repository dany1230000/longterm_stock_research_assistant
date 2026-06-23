# 00631L v4.68 Public Batch Offset Guidance

v4.68 improves the public maintenance action items for ETF history backfill.

## What Changed

- When the public backend has a known ETF history `readyCount`, but local batch
  resume state has no usable next offset, the maintenance summary suggests a
  concrete `--start-offset` based on the ready count.
- Example action item:

```cmd
scripts\00631l_public_etf_catalog_batches.cmd --start-offset 15 --soft-fail
```

## Why

Public ETF history can be imported gradually. A precise offset makes the next
maintenance step clearer and avoids repeatedly checking the same early catalog
rows when the public backend has already imported some ETF history.

## Validation

- Unit test covers ready-count based offset guidance.
- `scripts\00631l_public_maintenance_status.cmd --soft-fail` remains read-only.
- WARN remains acceptable when public deployment or ETF history import is still
  catching up and `failures=[]`.
