# 00631L v4.60 Catalog Seed Fallback

Release goal: let a newly deployed public backend use the committed official ETF catalog snapshot before its persistent volume has imported a local `twse_etf_catalog.json`.

## What Changed

- Added `ETF_CATALOG_SEED_PATH`.
- Backend catalog reads now use this order:
  1. local persistent catalog cache
  2. committed official catalog seed
  3. unavailable/error status
- Seed-only catalog responses are labeled `static_official`.
- `POST /api/etf/history/update?fromCatalog=true` can select ETF codes from the catalog seed when the local catalog file is missing.

## Why

Remote public maintenance previously updated only the default ETF basket when the deployed backend had no imported catalog. The static GitHub Pages export already had a broad catalog seed, so the public backend should be able to bootstrap from the same committed official snapshot without pretending it is live data.

## Environment

```cmd
ETF_CATALOG_PATH=/data/00631l/twse_etf_catalog.json
ETF_CATALOG_SEED_PATH=backend/seeds/twse_etf_catalog_seed.json
```

The seed is official static data. It is not live intraday data. After `POST /api/etf/catalog/import` succeeds, the persistent local catalog is used instead.

## Remote Maintenance

```cmd
scripts\00631l_remote_maintenance.cmd --mode daily --etf-from-catalog --etf-limit 50 --etf-offset 0 --retry-count 2 --retry-delay-seconds 3 --soft-fail
```

Use offsets to fill the catalog in batches.
