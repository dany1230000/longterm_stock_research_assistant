# 00631L v4.62 Public Batch Resilience

Release goal: make public ETF catalog history maintenance safer when the hosted backend returns a transient HTTP error or restarts during a batch.

## What Changed

- `scripts\00631l_public_etf_catalog_batches.cmd` now keeps `nextOffset` on the failed offset when a batch returns `FAIL`.
- If the final ready count is lower than the initial ready count, the runner reports a warning that the public backend ready count decreased.
- Action items now tell the operator to retry the failed offset instead of skipping ahead.

## Why It Matters

Hosted backends can restart while fetching TWSE history. When that happens, the safest program action is to retry the same offset and verify `/api/etf/history/status` before continuing.

## Validation

This release adds a regression test for `HTTP 502` handling and keeps the release check path unchanged.
