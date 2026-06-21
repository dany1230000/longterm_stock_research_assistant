# 00631L lab v4.22 Incremental Price Update

Date: 2026-06-21

## Scope

v4.22 improves historical price update reliability. Daily price updates now default to an incremental fetch from the latest cached month instead of re-fetching the full 2014-present range every time.

## Changes

- Added `PriceHistoryStore.default_incremental_start_date`.
- Changed `scripts\00631l_update_price_history.cmd` to use incremental mode by default.
- Added `--full-refresh` for explicit full-history refreshes.
- Changed static public export `--update` to use the same incremental default.
- Fixed the update summary so `fetchedRows` means rows fetched in the current request and `rowCount` means total cached rows.

## Validation Notes

- Incremental update fetched only the 2026-06 TWSE STOCK_DAY month.
- Local price history coverage reached 2014-10-31 to 2026-06-18.
- Static public export reached rowCount 2832 with coverage 2014-10-31 to 2026-06-18.

## Boundaries

- No generated static data is committed.
- No fake historical rows are created.
- Full refresh remains available when needed.
