# 00631L v17.01 overview quote density

v17.01 trims the mobile overview quote header so the first screen reads more
like a compact market app.

## Changes

- The embedded quote price is slightly smaller on phone width.
- The embedded premium/discount box is narrower and uses tighter padding.
- The overview height guard is stricter so future changes do not make the first
  screen drift back into an oversized header.

## Scope

This release does not change chart behavior, live/static data selection,
premium/discount calculation, backtest logic, or ETF data loading.
