# 00631L v15.59 tab identity guard

This release adds a phone layout guard for tab identity.

## Changed

- Widget coverage now verifies each bottom tab opens its own first-screen
  content on phone width.
- The guard checks overview, history/backtest, position, AI, and settings do not
  reuse the same hero or market stack.

## Design intent

Each tab should feel like a dedicated tool surface. The overview can lead with
the market stack, but history, position, AI, and settings must open directly on
their own primary content.

## Verification

- `flutter test test\etf_00631l_widget_test.dart --name "phone tabs open distinct first-screen content"`
- Full release validation remains required before tagging.
