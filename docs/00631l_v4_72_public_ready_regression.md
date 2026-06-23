# 00631L lab v4.72 public ready regression

v4.72 improves public backend maintenance diagnostics when ETF history
`readyCount` moves backward after a catalog batch.

## What changed

- `scripts\00631l_public_maintenance_status.cmd` compares the current public
  ETF history `readyCount` with the latest local public catalog batch state.
- If the public backend reports fewer ready ETF histories than the latest batch
  state, the summary includes `catalogBatchReadyRegression`.
- The script adds a warning and action item to check the public backend
  persistent data volume and redeploy status before continuing catalog batches.

## Why

Hosted backends can restart or roll between instances. If the persistent data
path is not mounted consistently, `readyCount` can drop even after a batch made
progress. Continuing larger batches in that state can hide the real deployment
problem.

## Verification

- `py -m unittest backend.tests.test_public_maintenance_status`
- Full release validation remains covered by `scripts\00631l_release_check.cmd`.

This is a deployment maintenance diagnostic only. It does not add trading
signals, forecasts, notifications, or TX live expansion.
