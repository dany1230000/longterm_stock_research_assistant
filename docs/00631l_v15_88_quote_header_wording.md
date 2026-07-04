# 00631L v15.88 Quote Header Wording

## Scope

This release cleans the phone quote header wording so the public first screen
looks like a product surface rather than a debug/status dump.

## Changes

- 00631L quote name uses readable `元大台灣50正2`.
- Quote source captions use `行情 · ...` labels.
- Intraday quote badge now displays `盤中`; stale data displays `過期`.
- Catalog and historical fallback quotes are labelled `清單` and `歷史收盤`.
- No quote source, price calculation, fallback order, or live backend behavior
  changed.

## Validation

- Focused widget tests cover the quote header and selected ETF historical close
  fallback wording.
- Full release validation remains required before tagging this release.
