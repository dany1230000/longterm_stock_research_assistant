# 00631L v15.58 comparison summary density

This release tightens the ETF comparison summary on phone width.

## Changed

- The comparison summary now uses a one-line phone summary:
  selected codes, common range, and row count.
- Candidate and readiness counts remain in the readiness strip below.
- Widget coverage keeps the comparison summary short before the selector panel.

## Design intent

ETF comparison should feel like a selector and chart tool, not a maintenance
paragraph. The page still supports custom baskets and same-type presets without
forcing every comparison against 00631L.

## Verification

- `flutter test test\etf_00631l_widget_test.dart --name "ETF comparison action strip uses compact labels on phone width"`
- Full release validation remains required before tagging.
