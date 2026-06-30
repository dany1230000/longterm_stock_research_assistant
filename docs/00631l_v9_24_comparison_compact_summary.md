# 00631L lab v9.24 comparison compact summary

## Scope

v9.24 tightens the ETF comparison section on the history/backtest page. The
comparison controls already support a user-selected basket; this release makes
that state visible as a compact mobile-first summary.

## Changes

- Added a compact comparison summary strip.
- The strip shows selected ETF codes, common date range, total row count, and
  that no fixed benchmark is applied.
- Empty comparison state remains explicit: no selected ETF means no chart.
- Existing filter chips and manual ETF selection remain unchanged.

## Data Rules

- Comparison uses only ETF histories with at least two verified price rows.
- The chart recalculates each selected ETF from the shared visible range.
- Static public data, live proxy data, and fallback status labels remain
  truthful; fallback data is not presented as live.

## Verification

- Widget test covers the compact summary strip and confirms that selecting one
  ETF does not implicitly include 00631L in the comparison basket.
- Standard release checks should still be run before tagging.
