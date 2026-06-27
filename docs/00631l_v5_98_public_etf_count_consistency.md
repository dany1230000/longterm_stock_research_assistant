# 00631L lab v5.98 public ETF count consistency

v5.98 makes the public static-data checker more explicit about ETF data-library
counts.

## What Changed

- `scripts\00631l_check_public_static_data.cmd` now reports:
  - `etfPriceHistoryRowCount`
  - `etfPriceHistoryCompletionTotal`
  - `etfPriceHistoryCompletionGap`
- The compact summary prints `etfRows` and `etfCompletionGap`.
- If the ETF history index has more symbols than the current catalog snapshot,
  the checker returns `WARN` with a clear explanation.

## Why

After v5.97, public Pages can probe missing ETF histories during deployment.
That makes it possible for the ETF history index and the latest catalog snapshot
to differ briefly. The public checker now shows both counts instead of hiding the
difference behind one catalog number.

This is a data-quality visibility change only. It does not change historical
calculations, live data sources, or app behavior.
