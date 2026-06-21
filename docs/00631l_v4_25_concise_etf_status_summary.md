# 00631L lab v4.25 concise ETF status summary

Completed: 2026-06-21

## Scope

- Added `--summary-only` for `scripts\00631l_import_etf_price_history.cmd --status-only`.
- `scripts\00631l_release_check.cmd` now uses the concise ETF price-history status path.
- The concise output keeps `rowCount`, `readyCount`, coverage range, validation counts, sample ETF codes, and the number of suppressed detailed rows.
- Detailed per-ETF validation remains available through `scripts\00631l_validate_etf_price_history.cmd` or `scripts\00631l_import_etf_price_history.cmd --status-only` without `--summary-only`.

## Why

The generic ETF history cache now covers many catalog symbols. Dumping every ETF item in the release check made daily output hard to scan. v4.25 keeps the daily maintenance signal short without removing detailed validation tools.

## Verification

- Target backend tests cover the summary helper and release-check guard.
- Full release validation still runs the ETF price-history status check.
- No generated data, exports, cache, or local state are committed.
