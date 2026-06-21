# 00631L lab v4.24 ETF History Incremental Updates

Date: 2026-06-21

## Scope

v4.24 applies the same incremental update behavior to generic ETF price history imports. This improves the data foundation for ETF search, selected ETF views, and future ETF comparison work.

## Changes

- Added `EtfPriceHistoryStore.default_incremental_start_date`.
- `scripts\00631l_import_etf_price_history.cmd` now defaults to per-symbol incremental updates.
- Added `--full-refresh` for explicit broad refreshes.
- Backend ETF price-history update also uses per-symbol incremental starts when no start date is provided.
- Import output includes `updateMode` per ETF.

## Validation Notes

- 0050 import ran with `updateMode=incremental`, `requestedMonths=1`, and updated coverage to 2026-06-18.
- Unit coverage verifies the per-ETF incremental start date.

## Boundaries

- No generated ETF history cache is committed.
- Existing explicit `--start-date` calls still work for controlled backfills.
- This does not create full per-ETF research rooms yet; it only strengthens the price-history data layer.
