# 00631L lab v5.83 Pages missing ETF batch

This release wires the missing-only ETF history batch into the public static build path.

## Changed

- `scripts\00631l_build_pages_static.cmd` now runs:

```cmd
scripts\00631l_import_missing_etf_batch.cmd --catalog-path backend\seeds\twse_etf_catalog_seed.json --limit 50 --start-date 2026-06-01 --allow-partial --summary-only --progress-every 10
```

- `.github\workflows\deploy_web.yml` now runs the equivalent Python command before static export.
- Public/static builds use `--start-date 2026-06-01` for this missing-only step so the deployment job stays bounded.
- Both paths keep `continue-on-error` or `allow-partial` behavior for broad ETF imports, so one unavailable ETF does not hide the rest of the static build.
- Static export still marks unavailable ETFs honestly; missing histories are not invented.

## Why this matters

The public GitHub Pages app can keep improving ETF history coverage during normal Pages builds. 00631L remains the complete research room; other ETFs become available for history, backtest, and comparison only when official price history is successfully imported.

Longer-range missing ETF backfills should still be run manually with
`scripts\00631l_import_missing_etf_batch.cmd` so their runtime can be watched.

## Boundaries

- No generated static data is committed.
- No fallback data is labeled as official.
- No investment guidance is added.
