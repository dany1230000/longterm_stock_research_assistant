# 00631L v4.66 Public Maintenance Status

Release goal: provide one short read-only command for public backend maintenance status.

## What Changed

- Added `backend/scripts/public_maintenance_status_00631l.py`.
- Added `scripts\00631l_public_maintenance_status.cmd`.
- The command combines:
  - public deploy drift
  - public backend readiness floors
  - public/local/static freshness comparison
- The output includes:
  - `overallStatus`
  - warning/failure counts
  - public release tag
  - ETF ready count
  - action items

## Usage

```cmd
scripts\00631l_public_maintenance_status.cmd --soft-fail
```

The command is read-only. It does not mutate public backend data.
