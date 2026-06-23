# 00631L lab v4.78 public deploy wait

v4.78 adds a read-only wait helper for public backend deployment.

## What Changed

- Added `backend/scripts/wait_public_deploy_00631l.py`.
- Added `scripts\00631l_wait_public_deploy.cmd`.
- Release check now runs the wait helper in `--dry-run` mode.

## Usage

After pushing a backend release, run:

```cmd
scripts\00631l_wait_public_deploy.cmd --attempts 12 --interval-seconds 10 --soft-fail
```

The helper repeatedly checks public deploy drift until the public backend
reports the expected release tag. It does not mutate backend data.

## Status Semantics

- `PASS`: the public backend release tag matches the expected release tag.
- `WARN`: the public backend is reachable but has not caught up yet, or a
  sample returned a recoverable status warning.
- `FAIL`: reserved for command/runtime errors; use `--soft-fail` for daily
  maintenance logs.

Run this helper before public ETF history catalog batches. If deployment has
not caught up, wait for Render or the chosen host to finish the deploy first.
