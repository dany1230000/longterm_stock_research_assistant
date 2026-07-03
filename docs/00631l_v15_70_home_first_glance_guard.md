# 00631L v15.70 home first-glance guard

This release tightens the phone home screen density guard.

## Changed

- Reduced the fixed phone market top bar height.
- Reduced the left-top ETF search pill vertical padding.
- Tightened the embedded quote header text line height and caption height.
- Reduced compact premium/discount box vertical padding.
- Tightened widget guards for the top bar, quote header, market stack, and
  first-screen chart position.

## Design intent

The overview page should open like a compact market app: symbol search, quote,
chart, date axis, and daily digest stay visible without a large decorative
header taking over the first screen.

## Verification

- `flutter test test\etf_00631l_widget_test.dart --name "00631L lab remains readable on phone width|overview phone first screen keeps market order"`
- `scripts\00631l_mobile_layout_check.cmd`
