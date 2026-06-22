# 00631L v4.59 Remote Retry And Post-Check

Release goal: make public backend maintenance less brittle when Render or another host briefly returns `502/503` on read-only status endpoints.

## What Changed

- `scripts\00631l_remote_maintenance.cmd` now supports:
  - `--retry-count`
  - `--retry-delay-seconds`
- Transient retry applies to read-only `GET` checks.
- Update `POST` requests are not blindly retried.
- `history_update` and `etf_history_update` now report post-check metadata:
  - `postCheckHttpStatus`
  - `postCheckRetryAttempts`
  - `updateHttpStatus` for ETF history update
- Non-critical read-only endpoints such as operations status and analysis summary treat transient `502/503` as `WARN`, not `FAIL`.

## Why

The daily remote maintenance flow can successfully update official/static history but then fail on a temporary status read. That should be visible, but it should not hide the fact that the data update completed.

## Recommended Commands

```cmd
scripts\00631l_remote_maintenance.cmd --mode daily --etf-from-catalog --etf-limit 50 --etf-offset 0 --retry-count 2 --retry-delay-seconds 3 --soft-fail
scripts\00631l_public_backend_status.cmd --soft-fail
scripts\00631l_compare_public_freshness.cmd --soft-fail
```

## PASS / WARN / FAIL

- `PASS`: update and post-checks completed.
- `WARN`: update may have completed but a non-critical read-only check or post-check was temporarily unavailable.
- `FAIL`: update endpoint failed, readiness failed, or a critical endpoint returned a non-recoverable HTTP error.

`WARN` does not mean data is wrong. It means the operator should inspect the status payload and rerun the read-only check.
