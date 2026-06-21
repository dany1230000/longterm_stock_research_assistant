# 00631L v4.29 legacy static tier summary

v4.29 improves static-public maintenance visibility for older generated static
data.

## Changes

- `static_export_status()` now falls back through three sources for ETF history coverage tiers:
  1. `manifest.json` `etfPriceHistoryCoverageTierCounts`
  2. `etf_price_history_index.json` `coverageTierCounts`
  3. legacy `etf_price_history/*.json` metadata
- The legacy fallback is read-only and does not rewrite generated static data.
- The fallback derives only coverage tiers from existing `coverageStart`, `rowCount`, and `sourceStatus` metadata.
- Missing metadata remains explicit; the code does not invent history rows or official values.

## Result

Older static exports can still produce a useful compact status line such as:

```text
[summary] overallStatus=PASS rows=2832 coverage=2014-10-31..2026-06-18 etfReady=15 etfRows=15 tiers=long_term:8,recent:220,unavailable:0,error:0
```

## Scope

- No live source behavior changed.
- No static generated data is committed.
- This release only improves status reading and maintenance logs.
