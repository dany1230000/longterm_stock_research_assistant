# 00631L lab v5.82 missing ETF batch helper

This release adds a safer local helper for continuing ETF price-history coverage work.

## New script

`scripts\00631l_import_missing_etf_batch.cmd`

Default behavior:

```cmd
scripts\00631l_import_missing_etf_batch.cmd
```

Runs:

```cmd
py backend\scripts\import_etf_price_history.py --from-catalog --missing-only --limit 25 --allow-partial --summary-only --progress-every 5
```

## Why this exists

- It imports only ETF codes that are still missing ready price-history rows.
- It keeps broad ETF data backfill work resumable and less error-prone.
- It uses `--allow-partial` for broad official-data fetches so one unavailable ETF does not hide the rest of the batch.
- It does not commit generated local data.

## Import selection fix

`--missing-only --from-catalog --limit N` now filters ready ETFs first, then applies
`offset` / `limit` to the missing-code list. This prevents a batch from doing
nothing just because the first catalog rows already have ready history.

## Override example

```cmd
scripts\00631l_import_missing_etf_batch.cmd --limit 5 --allow-partial --summary-only --progress-every 1
```

## Boundaries

- Data still comes from the existing official TWSE price-history importer.
- If TWSE has no usable history for a code, the app marks that ETF as `僅清單資料`.
- No values are invented to fill gaps.
- No investment guidance is added.
