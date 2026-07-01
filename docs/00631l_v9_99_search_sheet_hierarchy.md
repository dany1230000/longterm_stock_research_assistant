# 00631L v9.99 search sheet hierarchy

## Scope

This release tightens the left-top ETF search and switch sheet.

## Changes

- Adds a compact current-selection panel so users know which ETF is active
  before searching.
- Keeps each ETF result row focused on code, name, status, and price.
- Moves capability details, data basis, and full readiness badges into a
  per-result `更多資料` disclosure.
- Keeps the database status panel available but out of the main result list.

## Product Rule

Search should behave like a stock app selector. The first scan should answer:
what ETF is this, whether it has usable history, and whether it can become the
current research target. Detailed data provenance remains available on demand.

## Validation

- Symbol search widget tests cover the current selection panel, compact result
  hierarchy, lazy catalog loading, catalog-only rows, and ranked matching.
- Full release validation remains required before publishing.
