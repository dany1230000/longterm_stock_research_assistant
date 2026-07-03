# 00631L lab v15.34 intraday quote header wording

This release improves the main quote badge wording.

## Changes

- When an intraday quote is available and fresh, the quote header shows `盤中`.
- Stale intraday data still shows `過期`.
- Underlying source status values are unchanged; only the main user-facing badge
  is simplified.

## Validation

- Widget coverage verifies a fresh official intraday quote renders `盤中` and
  does not show cache-oriented wording in the main quote header.
