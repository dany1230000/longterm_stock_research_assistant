# 00631L v8.9 Public ETF History Carry Forward

## Goal

Keep the public GitHub Pages static ETF history library from regressing when a
new build starts with an empty backend data directory.

## What Changed

- Added `backend/scripts/restore_public_etf_price_history.py`.
- Added `scripts/00631l_restore_public_etf_price_history.cmd`.
- GitHub Pages now restores deployed `etf_price_history/*.json` rows before it
  restores import-attempt evidence and before it exports the next static bundle.
- Local Pages builds now do the same by default.
- The committed ETF price-history seed directory can hold verified official
  baseline rows so static-public mode is reproducible even when live sources are
  rate-limited.

## Source Truthfulness

The restore step only copies previously deployed static JSON rows that already
carry row-level source contracts such as `twse_stock_day_json` or
`tpex_etf_historical_daily_json`. It does not invent missing rows and it does not
turn unavailable data into official history.

## Expected Result

Static-public mode should keep the ETF history readiness close to the latest
validated local export. If the public site loses individual ETF history files,
the workflow still has the committed seed baseline and official refresh steps.

## Commands

```cmd
scripts\00631l_restore_public_etf_price_history.cmd
scripts\00631l_build_pages_static.cmd
scripts\00631l_check_public_static_data.cmd --max-unclassified-gap 0
```

## Remaining Limit

If an ETF has no official TWSE or TPEx historical rows, it remains unavailable
and should stay visible as a data gap.
