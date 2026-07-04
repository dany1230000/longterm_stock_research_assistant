# 00631L v15.94 Position Metric Strip

## Scope

This release tightens the phone position page first screen.

## Changes

- Position metrics now use one horizontal strip on phones instead of a 2x2
  grid.
- Market value, unrealized P/L, cost, and allocation remain grouped together.
- Long values scale down inside each metric tile to avoid clipped numbers.
- No position calculation, local storage, export, or clear behavior changed.

## Validation

- Widget coverage verifies the position metric strip is compact and horizontally
  scrollable on phone width.
- Full release validation remains required before tagging this release.
