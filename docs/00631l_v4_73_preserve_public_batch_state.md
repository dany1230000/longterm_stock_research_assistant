# 00631L lab v4.73 preserve public batch state

v4.73 protects the local public ETF catalog batch state file from being
overwritten by low-information catalog failures.

## What changed

- When `/api/etf/catalog/status` is unavailable and reports zero rows, the batch
  runner still returns a WARN payload.
- If an existing state file already contains useful progress such as
  `finalReadyCount`, `nextOffset`, or `failedOffset`, the runner preserves that
  state instead of replacing it with zero-count metadata.
- A new unit test covers the preservation behavior.

## Why

The public backend can temporarily return catalog unavailable during redeploys
or transient platform issues. That state is useful as a warning, but it should
not erase the last known resume point from a prior batch.

## Verification

- `py -m unittest backend.tests.test_public_catalog_batch_runner`
- Full release validation remains covered by `scripts\00631l_release_check.cmd`.

This is a maintenance-state reliability patch only. It does not add trading
signals, forecasts, notifications, or TX live expansion.
