# 00631L lab v5.70 broad ETF price seed

Date: 2026-06-24

## Scope

v5.70 makes GitHub Pages static ETF history readiness reproducible by committing validated ETF price-history seed files.

## Changes

- `backend/seeds/etf_price_history_seed/` now contains a broad validated seed set.
- The seed set is generated from local official TWSE STOCK_DAY cache rows.
- Only ETF histories with at least 2 rows and zero validation failures are included.
- `all-catalog` static export merges every available seed file before building the public static index.
- GitHub Pages can keep ready ETF history stable even if a live TWSE request returns fewer rows during a workflow run.

## Current Seed Coverage

- Seeded ETF histories: 230
- Skipped local cache histories: 1, because it had only one price row at generation time
- Catalog index remains complete; missing or too-short symbols stay visible as `unavailable`

## Validation

Run:

```cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
scripts\00631l_build_pages_static.cmd
git diff --check
```
