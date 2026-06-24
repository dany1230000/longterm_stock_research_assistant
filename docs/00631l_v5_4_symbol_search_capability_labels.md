# ETF lab v5.4 - symbol search capability labels

Completed: 2026-06-24

## Scope

This release improves the left-top ETF / stock search sheet. It makes the data
available after switching ETF clearer before the user taps a result.

## Changes

- ETF search results now show a capability line:
  - `切換後：歷史 / 回測 / 比較` when imported price history is available.
  - `切換後：catalog 快覽，歷史資料不足` when only catalog fields are available.
- Existing history readiness badges remain visible.
- Catalog-only ETF selections still show missing-history guidance after switch.
- Widget tests cover both history-ready and catalog-only search results.

## Data Notes

- This does not import new ETF data.
- 00631L remains the only ETF with official daily holdings and live intraday NAV
  integration.
- Other ETFs use TWSE catalog and imported price history where available.

## Validation

- `flutter test test\etf_00631l_widget_test.dart`
- Full release validation is required before tagging.
