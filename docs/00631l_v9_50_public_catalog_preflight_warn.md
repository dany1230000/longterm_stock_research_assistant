# 00631L lab v9.50 - public catalog preflight WARN handling

Date: 2026-06-30

## Goal

Keep public ETF catalog history maintenance moving when preflight checks only
report warnings and no failures.

## Change

- `scripts\00631l_public_etf_catalog_batches.cmd` now records preflight WARN
  details but continues the requested batch when `failures=[]`.
- Preflight `FAIL` or non-empty failures still block remote catalog batches.
- Batch output keeps a `public_catalog_preflight` step so operators can see why
  the final status is WARN.
- Action items from warning-only preflight checks are preserved alongside batch
  next-step guidance.

## Why

The public backend can be healthy enough to update ETF history while still
reporting expected warnings such as persistence marker confirmation or missing
git SHA metadata. Treating every WARN as a hard stop prevented one-row catalog
batches from reducing the public/static ETF history gap.

## Scope

This release changes maintenance runner control flow only. It does not change
ETF selection behavior, TX live sourcing, notification behavior, automated
actions, or investment guidance.
