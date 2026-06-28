# 00631L lab v6.93 - static catalog history-index reconcile

## Goal

Keep the public static ETF catalog aligned with the ETF price-history index even
when the live TWSE all-ETF catalog endpoint is temporarily unavailable and the
committed seed catalog is older than the history index.

## Problem

After v6.92, the public Pages static check could still report:

- ETF catalog rows: 343
- ETF price-history index rows: 347
- Out-of-catalog rows: 4

This happened because the Pages build can fall back to a committed seed catalog
that is smaller than the already-exported ETF history universe.

## Changes

- Static export now reconciles `etf_catalog.json` against
  `etf_price_history_index.json` before writing the public files.
- Missing catalog rows are appended from the history index with
  `sourceStatus: static_history_index`.
- No price-history rows, market prices, NAV values, or holdings are fabricated.
- `etfPriceHistoryOutOfCatalogCount` now uses actual ETF code sets instead of
  only comparing row counts.

## Expected Public Result

The public static check should report:

- `etfCatalogRows=347`
- `etfRows=347`
- `etfOutOfCatalog=0`
- `etfUnclassified=0`

## Validation

- Targeted backend tests cover history-index catalog reconciliation.
- Full validation: Flutter analyze/test/build, backend tests, release check
  with acceptable WARN-only output and `failures=0`, and `git diff --check`.
