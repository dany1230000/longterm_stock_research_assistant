# ETF price validation and split adjustment v4.12

This patch tightens ETF price-history correctness for the ETF research room.

## What changed

- Multi-ETF price history now applies known split adjustment by ETF code.
- Raw TWSE OHLC values are preserved.
- Performance, charts, comparison, and backtest calculations use `adjustedClose` when a known split event exists.
- The import flow validates saved rows after every update.
- `scripts\00631l_import_etf_price_history.cmd --status-only` now reports validation failure and warning counts.
- `scripts\00631l_validate_etf_price_history.cmd` is a dedicated validation alias.
- Static public export can use `--multi-etf-codes all-local` to include every locally saved ETF history that has at least two rows and zero validation failures.

## Known split events

| ETF | Effective date | Ratio | Effect |
| --- | --- | --- | --- |
| 0050 | 2025-06-18 | 1 old unit to 4 new units | Pre-event prices use factor 1/4. |
| 00631L | 2026-03-31 | 1 old unit to 22 new units | Pre-event prices use factor 1/22. |

If another ETF later shows a split-like discontinuity, add the official event to `ETF_PRICE_ADJUSTMENT_EVENTS_BY_CODE` in `backend\app\etf_price_history.py`, then rerun import and validation.

## Validation checks

The validator checks:

- duplicate dates
- missing dates
- non-positive close values
- OHLC consistency
- large adjusted daily moves
- known split boundary adjustment factors

Hard validation failures make the status command return non-zero. Large adjusted moves are warnings unless they indicate a known bad split adjustment.

## Commands

```cmd
scripts\00631l_import_etf_price_history.cmd --start-date 2019-01-01
scripts\00631l_import_etf_price_history.cmd --from-catalog --start-date 2026-06-01 --allow-partial
scripts\00631l_validate_etf_price_history.cmd
scripts\00631l_export_static_data.cmd --update --multi-etf-codes all-local
scripts\00631l_release_check.cmd
```

Generated data stays in ignored local/static output folders and should not be committed.
