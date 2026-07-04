# 00631L v15.75 overview summary density

This release tightens the phone overview daily summary card.

## Changed

- Reduced compact overview summary padding and vertical gaps.
- Reduced mobile holdings digest chip spacing.
- Added a widget guard for the full mobile daily summary card height.

## Design intent

The home page should keep quote, chart, date axis, daily data sentence, and
holdings digest visible without making the post-chart summary feel like a large
secondary card.

## Verification

- `flutter test test\etf_00631l_widget_test.dart --name "00631L lab remains readable on phone width|overview phone first screen keeps market order|overview includes official holdings context on phone"`
- `scripts\00631l_mobile_layout_check.cmd`
