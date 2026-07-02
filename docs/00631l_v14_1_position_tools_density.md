# 00631L v14.1 position tools density

## Goal

Keep the position page focused on the account summary and primary local input
flow on phones.

## Changes

- The first position screen keeps the account summary, shares, average cost, and
  save/update action visible.
- Export JSON and clear-local-data controls move under the `持倉工具` expansion
  panel after a position exists.
- Optional fields and estimate details remain behind expansion panels.

## Validation

- Updated position widget tests so export/clear controls are hidden until
  `持倉工具` is expanded.
- Kept phone-width input layout checks for the shares and average-cost row.
