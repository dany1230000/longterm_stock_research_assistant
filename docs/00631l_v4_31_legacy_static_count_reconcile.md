# 00631L v4.31 legacy static count reconcile

v4.31 reconciles legacy static ETF history row counts with the tier counts
derived in v4.29.

## Changes

- `static_export_status()` now derives row count, ready count, latest data time, and coverage tiers together when reading legacy `etf_price_history/*.json` files.
- The compact static export status line no longer mixes old manifest counts with derived tier counts.
- Existing manifest/index metadata still takes priority when it contains complete tier metadata.

## Result

Older generated static folders can now report a consistent summary:

```text
[summary] overallStatus=PASS rows=2832 coverage=2014-10-31..2026-06-18 etfReady=228 etfRows=228 tiers=long_term:8,recent:220,unavailable:0,error:0
```

## Scope

- Read-only status improvement.
- No generated static data is committed.
- No live source or import behavior changed.
