# 00631L v15.72 mobile comparison header

This release shortens the ETF comparison entry on phone width.

## Changed

- Added a compact phone-only ETF comparison header.
- Kept the full comparison section header for wider screens.
- Reduced the phone gap before the comparison summary.
- Added a widget guard for the phone comparison header height.

## Design intent

The history/backtest page should keep date controls, chart context, and backtest
controls ahead of ETF comparison detail. On phones, comparison still remains
available, but it opens with a short status row instead of a large explanatory
card.

## Verification

- `flutter test test\etf_00631l_widget_test.dart --name "ETF comparison action strip uses compact labels on phone width|ETF comparison chips update the selected basket|selected ETF history distinguishes close-mirrored adjustment"`
- `scripts\00631l_mobile_layout_check.cmd`
