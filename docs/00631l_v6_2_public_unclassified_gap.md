# 00631L lab v6.2 public unclassified ETF gap

v6.2 adds an explicit public static-data check metric for ETF gaps that have not
yet been probed.

## What Changed

- `scripts\00631l_check_public_static_data.cmd` now reports:
  - `etfPriceHistoryUnclassifiedGapCount`
- The compact summary prints `etfUnclassified`.
- The value is derived from `etfPriceHistoryGapReasonCounts.not_saved`.

## Why

After v6.1, the public Pages workflow can carry attempt evidence forward and run
multiple missing-ETF batches. The remaining gap can now be split into:

- classified gaps, such as `official_empty` or `source_error`
- unclassified gaps, still shown as `not_saved`

This makes the next maintenance target easy to read from one public check.

## Data Boundary

The new metric is a status label only. It does not change ETF price history,
backtest calculations, static data export, or live data sources.
