# 00631L lab v9.83 symbol search readability

## Goal

Make the left-top ETF search results easier to scan on mobile while preserving
truthful data-readiness labels.

## Changes

- Each ETF search result now shows one capability summary line instead of a
  long row of repeated badges.
- The live NAV scope remains visible because it changes how users should read
  non-00631L ETF rows.
- Hidden test anchors still preserve coverage for history, backtest, compare,
  AI context, and catalog-only states.
- The selected ETF overview digest now states whether the current ETF can be
  used for history, backtest, comparison, and AI context.

## Validation

- Widget tests cover ready ETF search rows, catalog-only ETF rows, selected ETF
  switching, and the selected ETF usable-scope line.
- No data source behavior changed. Live proxy, static public data, and mock
  fallback keep their existing status labels.
