# v4.52 backend ETF seed history fallback

## Purpose

v4.51 fixed the 00631L price-history fallback for a new public backend with an empty persistent volume. v4.52 applies the same reliability rule to the multi-ETF price-history store used by ETF search, selected ETF history, and comparison context.

## Behavior

- Seed directory: `backend/seeds/etf_price_history_seed/`.
- Config key: `ETF_PRICE_HISTORY_SEED_DIR`.
- Empty local ETF history plus seed rows returns `sourceStatus: static_official`.
- Local ETF history plus seed rows returns `sourceStatus: cached`.
- If the same ETF/date exists in both sources, the local cache row wins.
- `save_points()` writes only to `ETF_PRICE_HISTORY_DIR`; it does not copy seed rows into local app data.
- `scripts\00631l_import_etf_price_history.cmd --status-only --summary-only` now reads the configured seed dir.

## Why this matters

Public live backend mode can now show selected ETF history readiness and comparison context immediately after deployment, even before the persistent volume has been populated. The source labels remain explicit: seed-backed history is static official historical data, not live intraday data.

## Deployment notes

Recommended env:

```env
ETF_PRICE_HISTORY_DIR=/data/00631l/etf_price_history
ETF_PRICE_HISTORY_SEED_DIR=backend/seeds/etf_price_history_seed
```

Run normal maintenance after deployment:

```cmd
scripts\00631l_remote_maintenance.cmd --mode history
```

The maintenance import should then save local rows into the persistent volume. Local rows override same-date seed rows.

## Validation

- Store tests cover seed-only multi-ETF history and local-over-seed merge behavior.
- Endpoint tests cover `/api/etf/history/status` and `/api/etf/history/price?code=0050` with empty local history and configured seed dir.
- Script tests cover `backend/scripts/import_etf_price_history.py --status-only --summary-only --seed-dir ...`.
