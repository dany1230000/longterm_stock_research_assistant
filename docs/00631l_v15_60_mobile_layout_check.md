# 00631L v15.60 mobile layout check

This release adds a focused mobile layout QA script.

## Changed

- Added `scripts\00631l_mobile_layout_check.cmd`.
- The script runs the phone-width widget tests that guard the first screen,
  bottom tab identity, history/backtest controls, local position layout, symbol
  search, comparison controls, AI summary, settings, and day/night palette.
- Release check now runs the mobile layout check before the full Flutter test
  suite.

## Design intent

The app is now tuned as a phone-first ETF research tool. Layout regressions
should fail quickly before a broader release check finishes.

## Verification

- `scripts\00631l_mobile_layout_check.cmd`
- `scripts\00631l_release_check.cmd`
