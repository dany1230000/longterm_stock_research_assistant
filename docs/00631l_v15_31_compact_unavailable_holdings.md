# 00631L lab v15.31 compact unavailable holdings

This release improves the public/static overview when official holdings are not
available.

## Changes

- Embedded overview holdings unavailable state is now a single compact row.
- The larger title/subtitle block remains available for full holdings sections.
- The overview keeps static history, chart, and AI context visually dominant.
- The unavailable state remains truthful and is not converted into mock data.

## Validation

- Phone widget coverage now guards the unavailable holdings row height.
- Data source labels and fallback behavior are unchanged.
