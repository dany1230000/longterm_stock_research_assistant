# 00631L v6.40 compact holdings digest

## Goal

Make the overview holdings digest shorter on phone screens while keeping the
daily official contents visible in the overview.

## What Changed

- Replaced the tall holdings info-card grid with a horizontal digest strip.
- Kept the same three primary daily snapshot signals:
  - TX futures weight
  - TSMC stock weight
  - stock / futures / cash mix
- Preserved the warning that official holdings are daily snapshots, not
  intraday live composition.

## Validation

- Widget coverage verifies the compact holdings digest strip is rendered on
  phone width.
- Holdings source, parser, history, and calculations are unchanged.
