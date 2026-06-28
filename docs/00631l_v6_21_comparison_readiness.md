# 00631L lab v6.21 comparison readiness

v6.21 makes the ETF comparison section clearer when a selected ETF does not have enough imported price-history rows for a comparison chart.

## What changed

- The comparison panel now shows candidate, comparison-ready, and skipped counts.
- Skipped ETF codes are listed when their history has fewer than two price-history points.
- Skipped rows are not used in the return chart, comparison basket, or table.
- Catalog-only ETFs remain selectable in the app, but their unavailable history is labeled separately from usable comparison data.

## Data rules

- A comparison row needs at least two price-history points in the active range.
- Catalog-only rows are visible as data-status evidence only.
- Static, live, cached, mock, unavailable, and error states stay explicit.
- This release does not change any source parsing, price calculation, or ETF eligibility rule.

## Validation

- Widget coverage verifies that a catalog-only selected ETF is shown in skipped readiness metadata.
- Existing release checks still guard public static-data metadata and forbidden wording.
