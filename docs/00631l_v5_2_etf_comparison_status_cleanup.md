# 00631L lab v5.2 - ETF comparison status cleanup

Completed: 2026-06-23

## Scope

This release removes stale roadmap-style wording from ETF and settings pages.
It does not add new data sources or change trading scope.

## Changes

- ETF database copy now describes current behavior: search, switch ETF, and use
  history/backtest comparison when verified history exists.
- The catalog preview is labeled as a catalog snapshot, not a full long-term
  comparison.
- Removed the redundant "comparison preparation" block from the ETF page.
- Settings now reports ETF comparison as available in the history/backtest page
  instead of planned.
- Widget coverage continues to verify the self-selected comparison basket.

## Data Notes

- 00631L remains the only ETF with official daily holdings and live intraday NAV
  integration.
- Other ETFs use catalog and imported price history when available.
- Fallback and static data remain labeled by source status.

## Validation

- `flutter test test\etf_00631l_widget_test.dart`
- Full release validation is required before tagging.
