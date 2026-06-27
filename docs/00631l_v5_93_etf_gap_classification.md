# 00631L lab v5.93 ETF gap classification

v5.93 makes ETF price-history gaps easier to understand. The app no longer only
shows how many ETF histories are missing; it also exposes why the current saved
index considers them not ready.

## What Changed

- `EtfPriceHistoryStore.index_response()` now includes:
  - `missingCount`
  - `gapReasonCounts`
- Static public export writes the same gap classification into:
  - `etf_price_history_index.json`
  - `status.json`
  - `manifest.json`
- `/api/etf/00631l/operations/status` now forwards ETF history:
  - `missingCount`
  - `coverageTierCounts`
  - `gapReasonCounts`
- The ETF data-library UI shows a compact `資料缺口原因` row.

## Gap Reasons

- `not_saved`: no saved local or seed price history is available for that code.
- `insufficient_rows`: saved history exists but has fewer than two rows.
- `validation_error`: saved rows exist but validation failed.
- `source_error`: the source status is explicitly `error`.
- `not_ready`: fallback bucket for a saved item that is still not ready.

This release does not claim a missing ETF is officially empty. Official-empty
classification requires persisted import-attempt evidence and should be added in
a later data-ingestion release.

## User Impact

The app can now explain ETF data readiness in a more actionable way:

- available histories stay visible for comparison and search;
- missing histories show the current saved-index reason;
- static-public mode keeps the same labels as live/backend mode;
- fallback data is not presented as official live data.
