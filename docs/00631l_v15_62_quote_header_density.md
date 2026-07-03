# 00631L v15.62 quote header density

This release tightens the phone overview quote header.

## Changed

- The embedded overview premium/discount box now uses a two-line compact
  layout.
- The stock-app quote header height guard is tightened to 64px.
- Non-embedded quote cards keep the existing fuller premium/discount box.

## Design intent

The home page should surface quote, premium/discount, chart, and daily context
without letting the top quote area dominate the first phone screen.

## Verification

- `flutter test test\etf_00631l_widget_test.dart --name "00631L lab renders stock-app style quote header"`
- `scripts\00631l_mobile_layout_check.cmd`
