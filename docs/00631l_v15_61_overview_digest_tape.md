# 00631L v15.61 overview digest tape

This release tightens the overview phone digest below the chart.

## Changed

- The mobile holdings digest now uses one-line chips for `TX`, `2330`, and
  `CASH`.
- Secondary captions were removed from the phone first screen so the chart,
  daily context, and holdings weights read as one compact market tape.
- Widget coverage now verifies the three labels and keeps each chip at 24px or
  less.

## Design intent

The overview should read like a stock app first screen: chart, date context,
and the most important exposure values without decorative or redundant labels.

## Verification

- `flutter test test\etf_00631l_widget_test.dart --name "00631L lab remains readable on phone width"`
- `scripts\00631l_mobile_layout_check.cmd`
