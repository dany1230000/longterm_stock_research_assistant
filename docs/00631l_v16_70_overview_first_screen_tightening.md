# 00631L v16.70 Overview First Screen Tightening

This release trims the phone overview first screen without hiding the chart.

## Changes

- Overview chart stays visible by default but uses a shorter phone height.
- Market stack padding is reduced on phone width.
- Layout guards now require the overview stack and chart to remain tighter.
- No data source, parser, backtest, position, or AI behavior changed.

## Validation

- Phone overview widget tests verify quote, chart, date axis, touch detail, and holdings digest order.
- Full release check still covers forbidden wording, public/static data, backend tests, Flutter tests, and web build.
