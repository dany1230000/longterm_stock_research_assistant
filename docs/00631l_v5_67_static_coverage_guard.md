# 00631L Lab v5.67 Static Coverage Guard

v5.67 prevents GitHub Pages static data from moving backward when live TWSE
updates fail during a deployment.

The committed 00631L official price-history seed has been refreshed to:

```text
2014-10-31..2026-06-24
rows=2835
```

The static export command now supports:

```cmd
--max-coverage-age-days 7
```

When used with `--strict`, the export fails if `coverageEnd` is older than the
allowed age. This protects the public PWA from replacing newer static data with
an older fallback seed.

## What Changed

- Refreshed `backend/seeds/00631l_price_history_seed.jsonl`.
- Added a strict coverage-age guard to static export.
- GitHub Pages workflow uses `--max-coverage-age-days 7`.
- `scripts\00631l_build_pages_static.cmd` uses the same guard.
- Tests cover the guard and pipeline flags.

## Result

If TWSE is temporarily unavailable and the available seed/cache is too old, the
Pages workflow fails before deploying stale static price history. Existing
public data remains in place until the next successful run.
