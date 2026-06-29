# 00631L lab v8.5 ETF source-error retry

v8.5 lets ETF price-history maintenance retry source failures without repeatedly
probing symbols that TWSE already reported as empty.

## What changed

- `backend/scripts/import_etf_price_history.py` adds `--retry-source-errors`.
- When combined with `--missing-only --skip-attempted`, the importer:
  - skips prior official empty attempts;
  - retries prior `source_error` attempts;
  - keeps successful rows and official empty responses truthfully labeled.
- GitHub Pages static-data workflow uses the retry flag in missing-history
  batches.
- Local helper scripts use the same retry behavior.

## Why it matters

v8.4 fixed TWSE HTTP redirect handling. v8.5 makes the next maintenance run
actually revisit the old redirect-related `source_error` attempts, so they can
become usable history or official empty data after refetch.

## Boundary

This release does not add third-party historical data. If TWSE still returns no
rows, the app keeps that gap classified as official empty.
