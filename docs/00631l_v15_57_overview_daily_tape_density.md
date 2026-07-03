# 00631L v15.57 overview daily tape density

This release tightens the phone overview daily summary card.

## Changed

- The overview AI line and holdings digest use smaller vertical gaps.
- Mobile holdings chips use shorter padding.
- Widget coverage keeps the daily summary card within a compact phone height.

## Design intent

The public home screen should read quickly: quote, chart, daily status, and
holdings highlights without a report-like block between them.

## Verification

- `flutter test test\etf_00631l_widget_test.dart --name "00631L lab remains readable on phone width"`
- Full release validation remains required before tagging.
