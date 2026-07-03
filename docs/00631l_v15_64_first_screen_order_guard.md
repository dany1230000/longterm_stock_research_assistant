# 00631L v15.64 first-screen order guard

This release adds a phone first-screen order guard.

## Changed

- Widget coverage now verifies the overview order: quote header, chart, date
  strip, digest tape, and bottom navigation.
- `scripts\00631l_mobile_layout_check.cmd` runs that guard with the rest of the
  mobile layout checks.

## Design intent

The home page should be readable at a glance. The quote header should not grow
past the chart, and the chart plus daily digest should remain above the bottom
navigation on phone width.

## Verification

- `flutter test test\etf_00631l_widget_test.dart --name "overview phone first screen keeps market order"`
- `scripts\00631l_mobile_layout_check.cmd`
