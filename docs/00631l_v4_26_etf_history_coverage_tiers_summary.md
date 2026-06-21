# 00631L lab v4.26 ETF history coverage tiers

Completed: 2026-06-21

## Scope

- Added `coverageTier` and `coverageNote` to each saved ETF price-history status.
- Added `coverageTierCounts` to the multi-ETF history index, concise status output, static export index, static manifest/status, and frontend operations status.
- The settings/system ETF history row now shows long-term, recent, unavailable, and error counts.

## Tier Meaning

- `long_term`: enough local history for longer-range comparison/backtest context.
- `recent`: recent rows are present, but long-range comparison is limited.
- `unavailable`: no usable saved local price history.
- `error`: saved data failed validation.

## Notes

This does not fabricate missing history. It only labels the coverage quality of existing official/cached rows so UI and maintenance checks do not treat all ETF histories as equally complete.
