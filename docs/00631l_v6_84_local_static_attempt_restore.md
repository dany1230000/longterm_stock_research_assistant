# 00631L lab v6.84 local static attempt restore

## What changed

- Local `scripts\00631l_build_pages_static.cmd` now restores public ETF
  import-attempt evidence by default before static export.
- Use `--skip-restore-public-attempts` only for offline or intentionally
  isolated local builds.
- This aligns local static data status with the GitHub Pages pipeline, which
  already restores public attempt evidence before probing missing ETF history.

## Why

The public static data currently classifies every ETF price-history gap, but a
stale local ignored `web\00631l-static-data` folder can still show old
`not_saved` counts. Restoring public attempt evidence first keeps local status,
static export, and public checks consistent without inventing missing history.

## Data rules

- No missing ETF history is treated as usable history.
- `official_empty`, `source_error`, and `not_saved` remain status labels only.
- Static history is still separate from live intraday NAV.
- Public static history can support history/backtest when live backend is not
  available.
