# 00631L lab v4.80 persistence-first maintenance

v4.80 improves public maintenance guidance when the deployed backend has a data
persistence problem.

## What Changed

- `scripts\00631l_public_maintenance_status.cmd` now detects public persistence
  warnings from `scripts\00631l_public_backend_status.cmd`.
- When persistence is unhealthy, action items prioritize fixing the public
  backend data volume.
- ETF catalog batch suggestions are suppressed until persistence is healthy.

## Why

Public ETF history batches write local backend data. Running them while the
public data path is not writable can create confusing partial progress or
repeat the same failed offset. The maintenance summary now points to the
program setup issue first.

## Operator Action

Fix the public backend persistent volume, then run:

```cmd
scripts\00631l_public_backend_status.cmd --soft-fail
scripts\00631l_public_history_stability.cmd --sample-count 3 --interval-seconds 1 --soft-fail
scripts\00631l_public_maintenance_status.cmd --soft-fail
```

Only continue catalog batches when public backend status no longer reports
data persistence warnings.
