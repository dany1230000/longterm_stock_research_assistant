# 00631L lab v5.79 missing-only ETF import

This release makes broad ETF data backfills easier to resume and safer to run.

## What changed

- `backend/scripts/import_etf_price_history.py` now supports `--missing-only`.
- `--missing-only` skips ETF codes that already have ready price-history rows and no validation failures.
- The existing `--offset` and `--limit` controls remain available for explicit catalog slicing.
- README examples now recommend `--missing-only` for ordinary ETF history backfills.

## Useful command

```cmd
scripts\00631l_import_etf_price_history.cmd --from-catalog --missing-only --limit 25 --allow-partial --summary-only --progress-every 5
```

## Scope

- This does not commit generated ETF history data.
- This does not change TX live behavior.
- This does not add investment guidance.
