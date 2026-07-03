# 00631L v15.74 AI daily sentence

This release makes the compact phone AI insight read more like a daily
interpretation sentence.

## Changed

- Replaced token-style compact AI text with a short daily data sentence.
- Kept the same rule-based inputs: official holdings date, TX weight, TSMC
  weight, premium/discount state, and price-history row count.
- Added a widget guard that the compact AI insight contains daily-data wording.

## Design intent

The AI page should explain today's loaded data, not look like a debug token
row. Detailed rule-based facts remain in the existing expandable panels.

## Verification

- `flutter test test\etf_00631l_widget_test.dart --name "AI phone first screen keeps long details collapsed|AI full detail panel remains available on phone width|AI and settings sections render clean status wording"`
- `scripts\00631l_mobile_layout_check.cmd`
