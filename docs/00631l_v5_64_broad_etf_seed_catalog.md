# 00631L Lab v5.64 Broad ETF Seed Catalog

v5.64 fixes the static-public ETF history import path.

GitHub Pages runners do not have the local `backend/data/twse_etf_catalog.json`
file that exists on a maintainer machine after manual imports. The broad ETF
history step now points at the committed seed catalog:

```cmd
backend\seeds\twse_etf_catalog_seed.json
```

This keeps the public static build reproducible. It lets the Pages workflow and
`scripts\00631l_build_pages_static.cmd` import recent ETF history from the same
seed catalog before exporting `web\00631l-static-data`.

## What Changed

- GitHub Pages broad ETF import now passes `--catalog-path`.
- Local Pages static build now passes `--catalog-path`.
- Both paths use `--limit 0` so the seed catalog is not silently truncated.
- Backend tests guard the workflow and local script.

## Data Status

The static public app still labels generated files as static public data. Live
intraday NAV and official daily holdings still require a reachable backend.
No mock or fallback data is labeled as official.

## Verification

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
