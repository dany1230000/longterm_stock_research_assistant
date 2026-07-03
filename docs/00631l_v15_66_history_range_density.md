# 00631L v15.66 history range density

This release tightens the phone history/backtest first screen.

## Changed

- Reduced compact padding in the history/backtest top metric strip.
- Reduced compact padding and gaps in the date range control panel.
- Reduced compact date button and range metric tile height.
- Tightened widget guards for the history top strip, range context, metric row,
  and date controls.

## Design intent

The history/backtest page should get to the chart and range controls quickly on
phone width. Secondary quality and holdings details remain available lower on
the page or behind existing expansion panels.

## Verification

- `flutter test test\etf_00631l_widget_test.dart --name "history range context wraps on phone width"`
- `scripts\00631l_mobile_layout_check.cmd`
