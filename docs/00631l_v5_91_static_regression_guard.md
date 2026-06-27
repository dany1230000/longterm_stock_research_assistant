# 00631L lab v5.91 static regression guard

## Scope

v5.91 prevents GitHub Pages from replacing newer public static data with an
older local export.

v5.90 correctly made push builds faster, but the first push build showed an
important risk: if the clean runner cannot refresh the latest 00631L official
price rows, export can still pass the seven-day coverage guard while producing a
shorter public static history than the already-deployed page.

## Guard

New script:

```cmd
scripts\00631l_guard_static_public_regression.cmd
```

It compares:

- local `web\00631l-static-data\status.json`
- public GitHub Pages `00631l-static-data/status.json`
- public GitHub Pages `00631l-static-data/manifest.json` for ETF ready counts

It fails when:

- local coverage end is older than public coverage end
- local row count is lower on the same coverage date
- local ETF ready count is lower than public ETF ready count

If the public status cannot be fetched, the guard returns WARN instead of
blocking local validation.

## Deployment Behavior

`.github/workflows/deploy_web.yml` runs the guard after static export and before
web build/upload. This prevents stale static data from being published over a
newer public page.

The release also updates the committed 00631L official price-history seed to
`2026-06-26`, matching the latest validated local TWSE STOCK_DAY cache. That
lets a clean runner publish the same coverage even when the live update endpoint
is temporarily unavailable.

## Validation

`backend\tests\test_static_public_regression_guard.py` covers newer local data,
older local coverage, same-day row regression, and ETF ready-count regression.
`backend\tests\test_static_pages_pipeline.py` also checks the 00631L static seed
ends at `2026-06-26` with official TWSE rows.
