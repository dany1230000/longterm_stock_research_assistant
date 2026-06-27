# 00631L lab v5.95 public gap summary

v5.95 makes the public static-data check print ETF price-history gap reasons.

## What Changed

- `scripts\00631l_check_public_static_data.cmd` now reports:
  - `etfPriceHistoryGapReasonCounts`
  - a compact summary such as `official_empty=4,not_saved=113`
- The JSON payload keeps the full reason-count map for automation.
- Tests now cover the public check mapping.

## Why

v5.93 and v5.94 added gap classification and import-attempt evidence. This
release makes the same information visible in daily public Pages verification,
so maintenance checks can tell whether remaining gaps are untried, official
empty, validation-related, or source-related.
