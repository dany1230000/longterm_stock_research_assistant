# 00631L v16.04 Overview Mode Ribbon

## Scope

v16.04 makes the phone overview first screen clearer by adding a compact
frontend mode readout to the market stack data ribbon.

The ribbon now shows:

- `DAY`: latest official holdings date or source status
- `NAV`: intraday NAV time or source status
- `HIS`: historical price row count
- `MODE`: `live`, `static`, or `mock`

## Behavior

- The overview still keeps TX / 2330 exposure inside the holdings digest, not in
  the top ribbon.
- The mode label is intentionally short so it fits on phone width.
- Full source details remain available in the settings/account page and advanced
  panels.

## Data Scope

No data source behavior changed. The new label only reflects the existing
frontend mode selection.
