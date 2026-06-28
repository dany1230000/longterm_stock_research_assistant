# 00631L lab v6.77 ETF gap reason alignment

v6.77 improves ETF data-completion transparency.

## What changed

- Catalog-only ETF symbols that do not yet have local price-history rows are
  counted as `not_saved` in status summaries.
- Coverage tier counts now include those catalog-only missing symbols as
  `unavailable`.
- The status gap reason totals now add up to the reported completion gap.

## Why

Before this change, a local status check could report a completion gap of 116
symbols while only showing 20 classified gap reasons. The missing 96 symbols
were catalog entries without local history rows, not unknown data. Reporting
them as `not_saved` makes the maintenance state explainable.

## Scope

This change does not infer market data and does not create fake ETF history.
It only classifies missing local history rows more clearly.
