# 00631L lab v5.3 - compact overview exposure

Completed: 2026-06-23

## Scope

This release improves the mobile first screen by shortening the overview chart
and exposure area. It does not change holdings calculations or data sources.

## Changes

- Mobile overview now shows price chart plus one compact official exposure row.
- The full exposure bar layout remains on wider screens.
- The compact row keeps the key fields visible: holdings date, stock exposure,
  futures exposure, and cash/margin exposure.
- Widget tests now accept the compact exposure label on phone width.

## Data Notes

- Official holdings are still daily snapshots.
- Intraday NAV remains separate from daily holdings.
- Static public mode and live proxy mode are unchanged.

## Validation

- `flutter test test\etf_00631l_widget_test.dart`
- Full release validation is required before tagging.
