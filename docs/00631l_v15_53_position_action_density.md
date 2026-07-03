# 00631L v15.53 position action density

This release tightens the phone position page primary action.

## Changed

- Full-width position save/update actions now render as one line on phone width.
- Secondary actions still keep their compact labels inside the tools panel.
- Widget coverage checks the phone save action stays short.

## Design intent

The position page should feel like a small account input screen. The first screen should show the fields and primary save action without extra explanatory rows.

## Verification

- `flutter test test\etf_00631l_widget_test.dart --name "empty position starts with input card on phone width"`
- `flutter test test\etf_00631l_widget_test.dart --name "position phone values keep summary first without duplicate grid"`
- Full release validation remains required before tagging.
