# 00631L v15.55 history top metrics

This release tightens the phone history/backtest page top strip.

## Changed

- The phone history header now uses four fixed metrics: latest date, row count,
  total return, and maximum drawdown.
- The compact header no longer relies on a horizontal pill scroller for the
  primary history facts.
- Source and adjustment details remain available in the quality section.

## Design intent

The history/backtest page should open like a market app page: one glance at the
selected ETF history status, then date controls and charts. Maintenance-level
source details should not dominate the first screen.

## Verification

- `flutter test test\etf_00631l_widget_test.dart --name "history range context wraps on phone width"`
- Full release validation remains required before tagging.
