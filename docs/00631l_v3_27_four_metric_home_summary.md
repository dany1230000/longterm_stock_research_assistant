# 00631L lab v3.27 four-metric home summary

Completed date: 2026-06-13

## Scope

v3.27 further reduces the overview first screen.

## Changes

- The "today at a glance" panel now keeps only four high-signal metrics:
  - official holdings date
  - intraday estimated NAV
  - holdings exposure highlight
  - historical coverage
- Frontend mode is no longer duplicated inside the metric grid because it already appears in the app top bar.
- The change is UI-only and keeps the same data source behavior.

## Boundaries

- Static public history, live backend fallback, position tracking, backtest, and rule-based AI remain unchanged.
- TX live remains intentionally not connected.
- No investment guidance or trading workflow was added.
