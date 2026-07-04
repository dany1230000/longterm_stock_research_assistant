# 00631L v15.86 Comparison Selection Compact

## Scope

This release keeps the history/backtest ETF comparison selector available while
reducing the height of the expanded selector on phone width.

## Changes

- Phone width now renders comparison ETF chips in one horizontal scroll row.
- Comparison selector action buttons use a shorter compact button style.
- Desktop layout keeps the existing wrapped chip layout.
- No comparison calculation, data source, or fallback behavior changed.

## Validation

- Widget coverage verifies the phone comparison chip row and action strip stay
  compact.
- Full release validation remains required before tagging this release.
