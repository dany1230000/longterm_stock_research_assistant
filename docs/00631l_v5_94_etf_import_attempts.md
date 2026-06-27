# 00631L lab v5.94 ETF import attempts

v5.94 adds persisted import-attempt evidence for ETF price-history maintenance.
This is the next step after v5.93 gap classification: the app can now
distinguish a saved index gap from a recent official-empty STOCK_DAY attempt.

## What Changed

- `EtfPriceHistoryStore` can save and read per-code import attempts under:
  - `backend/data/.../_attempts/<ETF>.json`
- `backend/scripts/import_etf_price_history.py` records each attempted code:
  - attempt time
  - source status
  - source URL
  - requested month count
  - row count
  - warnings
  - error message
  - update mode and date range
- ETF history status now includes:
  - `lastImportAttempt`
  - richer `gapReason`
  - `gapReasonCounts.official_empty`

## Gap Reason Boundary

`official_empty` is used only when an import attempt has evidence that TWSE
STOCK_DAY returned no rows for the requested months. A code with no saved rows
and no attempt evidence remains `not_saved`.

This keeps the app from guessing why an ETF is missing. It only reports what the
local data pipeline can verify.

## Git Boundary

Import-attempt files live under backend local data directories. They are runtime
state and must not be committed.
