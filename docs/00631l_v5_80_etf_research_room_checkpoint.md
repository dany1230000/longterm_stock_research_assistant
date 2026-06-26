# 00631L lab v5.80 ETF research room checkpoint

This checkpoint summarizes the current ETF research-room state after the v5.75-v5.79 data and UX tightening pass.

## Completed in this pass

- Data trust:
  - Known ETF split events remain centralized in backend price-history normalization.
  - 00631L and 0050 split-adjusted histories use `adjustedClose` for performance and backtest calculations.
  - Selected ETF history distinguishes known split-adjusted data from close-mirrored adjusted fields.
- ETF history import:
  - Full refresh uses the earliest supported ETF history start date instead of a truncated 2019 baseline.
  - Local import supports catalog `--offset`.
  - Local import supports `--missing-only` so broad backfills skip ready ETF histories.
- Mobile UX:
  - Comparison wording now uses `比較組合` instead of the engineering term `basket`.
  - Chart date ticks use full `yyyy/MM/dd` labels.
- AI:
  - Selected ETF rule-based AI describes the latest historical close move.
  - Selected ETF AI explicitly distinguishes historical close data from intraday live data.

## Current data status

Latest static-public status observed during validation:

- 00631L price-history rows: 2835
- 00631L coverage: 2014-10-31 to 2026-06-24
- ETF catalog rows: 345
- ETF price-history ready: 230
- ETF price-history missing: 115
- Coverage tiers: long_term 8, recent 222, unavailable 115, error 0

The missing 115 ETF histories are data-coverage gaps. They should be filled with official TWSE data through controlled batches, not by committing generated local data or inventing values.

## Recommended next pass

1. Run small `--missing-only` backfill batches and inspect validation output.
2. Improve position and settings page density.
3. Keep selected ETF context consistent across overview, history/backtest, position, AI, and settings.
4. If broader ETF rooms are added, keep 00631L as the first complete room and mark other ETFs by available data scope.

## Boundaries

- No investment guidance.
- No automated trading.
- No generated static data committed.
- No fallback or mock data labeled as official.
