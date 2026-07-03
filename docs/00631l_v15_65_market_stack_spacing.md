# 00631L v15.65 market stack spacing

This release tightens the overview market stack spacing on phone width.

## Changed

- Reduced compact padding around the overview market stack.
- Reduced compact gaps between quote, chart, and the compact data ribbon.
- Tightened the phone market stack height guard from 360px to 350px.

## Design intent

The first screen should feel like a compact market board. The chart remains
visible, while surrounding whitespace stays controlled.

## Verification

- `flutter test test\etf_00631l_widget_test.dart --name "00631L lab remains readable on phone width"`
- `scripts\00631l_mobile_layout_check.cmd`
