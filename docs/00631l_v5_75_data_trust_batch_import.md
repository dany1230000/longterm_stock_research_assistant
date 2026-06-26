# 00631L lab v5.75 data trust and batch import

This release tightens ETF price-history correctness before adding broader ETF comparison UX.

## What changed

- Known ETF split events remain centralized in backend price-history normalization.
- 00631L and 0050 split-adjusted rows continue to use `adjustedClose` for performance and backtest calculations.
- Selected ETF history now distinguishes known split-adjusted data from rows where `adjustedClose` simply mirrors `close`.
- The multi-ETF import CLI now supports catalog `--offset` with `--limit`, so broad ETF history backfills can resume from the middle of the TWSE ETF catalog.
- Full refresh now uses the earliest supported ETF history start date instead of a truncated 2019 baseline.

## Why this matters

ETF comparison and backtest views must not imply full historical confidence when a selected ETF only has recent rows or close-mirrored adjustment fields. The app should prefer clear data coverage and adjustment context over decorative UI.

## Useful commands

```cmd
scripts\00631l_import_etf_price_history.cmd --status-only --summary-only
scripts\00631l_import_etf_price_history.cmd --from-catalog --offset 230 --limit 25 --allow-partial --summary-only --progress-every 5
scripts\00631l_validate_etf_price_history.cmd
```

## Still not changed

- No TX live behavior was changed.
- No investment guidance was added.
- Static generated data remains ignored and must not be committed.
