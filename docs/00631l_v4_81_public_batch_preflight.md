# 00631L lab v4.81 public batch preflight

v4.81 makes public ETF catalog history maintenance safer for a hosted backend.

## What changed

- `scripts\00631l_public_etf_catalog_batches.cmd` now defaults to one catalog
  item per run:

```cmd
scripts\00631l_public_etf_catalog_batches.cmd --batch-size 1 --max-batches 1 --soft-fail
```

- Non-dry-run catalog batches run preflight first:
  - public deploy drift check
  - public ETF history stability check
- If preflight returns WARN or FAIL, the runner stops before sending the remote
  update request.
- Current maintenance guidance now suggests single-item batches instead of
  broad batches.

## Why

Public hosted backends can return transient 502/timeout responses during ETF
history imports. Running one catalog item at a time keeps progress observable
and reduces the chance of confusing data persistence regressions with normal
import work.

## Current workflow

```cmd
scripts\00631l_wait_public_deploy.cmd --soft-fail
scripts\00631l_public_backend_status.cmd --soft-fail
scripts\00631l_public_history_stability.cmd --soft-fail
scripts\00631l_public_etf_catalog_batches.cmd --resume --batch-size 1 --max-batches 1 --soft-fail
```

If preflight reports persistence or deploy drift problems, fix those deployment
conditions before running more catalog batches.
