# 00631L lab v4.76 public history stability

v4.76 adds a read-only public ETF history stability check.

## What changed

- Added `backend/scripts/public_history_stability_00631l.py`.
- Added `scripts\00631l_public_history_stability.cmd`.
- The script samples public `/api/etf/history/status` multiple times and reports
  whether ETF history `readyCount` moves backward.
- Release check now includes a dry-run for the stability script.

## Daily maintenance use

```cmd
scripts\00631l_public_history_stability.cmd --soft-fail
```

If the summary reports `readyCountRegression > 0`, check the public backend
persistent data volume and redeploy status before continuing catalog batches.

## Why

The public backend can look healthy while ETF history readiness moves backward
between requests. A short read-only sampler makes that deployment/storage issue
visible before running more catalog updates.

## Verification

- `py -m unittest backend.tests.test_public_history_stability`
- Full release validation remains covered by `scripts\00631l_release_check.cmd`.

This is a deployment reliability diagnostic only. It does not add trading
signals, forecasts, notifications, or TX live expansion.
