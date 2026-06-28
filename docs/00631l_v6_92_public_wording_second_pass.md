# 00631L lab v6.92 - public wording second pass

## Goal

Finish the public wording cleanup started in v6.91 by removing the remaining
mixed Chinese/English phrases visible on mobile first screens.

## Finding

Public v6.91 screenshots still showed:

- `official holdings` inside the AI yellow summary.
- `完整 price history` under the history chart.
- Content-history labels that mixed `內容物` with `history`.
- English ETF comparison guidance.

## Changes

- Replaced remaining display strings with consistent product wording:
  content-history, official price history, price-history chart captions, and ETF
  comparison guidance.
- Kept `_aiDisplayText` mapping keys unchanged because they are required to map
  backend/model text into display text.
- Updated widget tests to assert the new public labels.

## Boundaries

- No parser, repository, price-history, backtest, or data-fetching behavior was
  changed.
- This is display-only polish.

## Validation

- Targeted widget validation passed with `flutter test
  test\etf_00631l_widget_test.dart`.
- Full validation passed: Flutter analyze/test/build, backend tests, release
  check with acceptable WARN-only output and `failures=0`, and
  `git diff --check`.
