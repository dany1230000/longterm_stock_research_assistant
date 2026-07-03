# 00631L lab v15.17 overview ribbon density

This release makes the phone overview first screen cleaner.

## Changes

- The compact data ribbon now contains only `DAY`, `NAV`, and `HIS`.
- Holdings weights such as TX and 2330 stay in the holdings digest below the
  chart instead of mixing into the data-status ribbon.
- The overview keeps live/static/mock mode labels truthful without making them
  compete with the main quote and chart.

## Validation

- Widget coverage verifies the compact ribbon shows only the data-status labels
  and does not show holdings labels.
- No backend, parser, export, or backtest behavior changed.
