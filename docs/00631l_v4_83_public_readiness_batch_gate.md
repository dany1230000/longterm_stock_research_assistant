# 00631L lab v4.83 public readiness batch gate

v4.83 tightens public maintenance guidance when the hosted backend readiness
endpoint reports a deployment problem.

## What changed

- `scripts\00631l_public_maintenance_status.cmd` now treats public readiness
  `FAIL` as a blocker for ETF catalog batches.
- In that state, the next action is:

```cmd
Fix public backend readiness before running ETF catalog batches.
```

- Catalog batch commands are suppressed until readiness recovers.

## Why

The public backend can still serve read-only seed/static data while `/ready`
reports a persistence problem, such as a non-writable data directory. Running
more catalog batches in that condition can hide deployment storage issues, so
the maintenance summary now prioritizes fixing readiness first.
