# 00631L lab v8.6 ETF completion clarity

v8.6 makes the ETF history database status easier to understand in the app.

## What changed

- The Settings ETF data-library panel now shows a compact completion strip:
  - usable price history;
  - official empty data;
  - source items still requiring attention;
  - unclassified items.
- The strip separates official empty ETF histories from source issues.
- The current public static data state is expected to show `source_error=0`
  after the v8.5 retry flow.

## Why it matters

Users need to know whether an ETF is missing because it has not been checked,
because the official source returned no rows, or because a source still needs
attention. This release keeps those states visible without turning missing data
into usable history.

## Boundary

No additional ETF history is inferred. Missing symbols remain unavailable unless
official source data exists.
