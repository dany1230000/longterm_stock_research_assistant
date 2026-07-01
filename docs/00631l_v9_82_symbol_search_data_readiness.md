# 00631L lab v9.82 symbol search data readiness

## Goal

Make the left-top ETF search sheet show data readiness before the user opens
advanced database details.

## Changes

- The search status row now always shows imported history coverage.
- If the ETF catalog has a gap, the status row shows the number still pending.
- The existing expandable database status remains available for detailed
  coverage and source checks.

## Validation

- Widget tests verify that full coverage does not show a pending-data label.
- Widget tests verify that catalog gaps show the pending count immediately in
  the search sheet.
