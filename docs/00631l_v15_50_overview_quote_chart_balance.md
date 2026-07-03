# 00631L v15.50 overview quote chart balance

This release keeps the overview page focused on the first phone screen.

## Changed

- Enlarged the compact overview chart so the one-year price shape is visible without opening another page.
- Shortened the compact daily AI line to one line on the overview page.
- Replaced the embedded holdings digest on phone width with a three-column strip for futures, 2330, and cash/margin.
- Kept full holdings details in the holdings page; the overview only shows the daily snapshot highlights.

## Design intent

The overview should behave like a quote screen: price first, chart second, then the daily data highlights. Supporting details remain available in their own sections.

## Verification

- `flutter test test\etf_00631l_widget_test.dart --name "00631L lab remains readable on phone width"`
- Full release validation remains required before tagging.
