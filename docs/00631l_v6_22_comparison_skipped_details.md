# 00631L lab v6.22 comparison skipped details

v6.22 adds compact reason details for ETF rows skipped from the comparison chart.

## What changed

- The comparison readiness strip now includes skipped-row detail chips.
- Each skipped chip shows the ETF code, active-range row count, and source status.
- The chart and comparison table still use only rows with at least two active-range price-history points.

## Why

Catalog-only or insufficient-history ETFs can be selected for context, but they should not be silently mixed into return comparisons. The skipped details make the data limitation visible without changing calculations.

## Scope

- No new data source.
- No source parsing changes.
- No eligibility rule changes.
- No investment guidance.
