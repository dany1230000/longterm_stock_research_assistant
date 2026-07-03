# 00631L v15.56 position metric strip

This release tightens the phone position account summary.

## Changed

- Saved-position metrics now stay in one horizontal row on phone width.
- The account card is shorter, so the edit panel and local tools appear sooner.
- Position calculations and local-only storage behavior are unchanged.

## Design intent

The position page should feel like an account snapshot first, not a long form.
Primary values stay visible, while secondary values can be scanned horizontally
inside the same compact strip.

## Verification

- `flutter test test\etf_00631l_widget_test.dart --name "position phone values keep summary first without duplicate grid"`
- Full release validation remains required before tagging.
