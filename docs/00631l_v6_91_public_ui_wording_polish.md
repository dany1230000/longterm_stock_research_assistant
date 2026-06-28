# 00631L lab v6.91 - public UI wording polish

## Goal

Make the public mobile app feel less like a debug surface by removing remaining
raw implementation phrases from history and AI screens.

## Finding

Public mobile screenshots after v6.90 still showed:

- `static_official` in the history header source badge.
- AI text fragments such as `official holdings`, `live intraday NAV`,
  `intraday NAV`, and `price history`.

These are useful internal data-contract labels, but they should not be primary
user-facing app text.

## Changes

- Expanded the AI display-text mapper with additional data-source phrases.
- Applied the mapper to today-snapshot AI bullets, selected-ETF AI bullets, and
  selected-ETF AI action items before rendering.
- Mapped the history header source badge through the existing source-status
  label helper.
- Added widget assertions that history and AI screens do not show the raw
  phrases.

## Boundaries

- No data-fetching, parser, price-history, backtest, or calculation behavior was
  changed.
- Raw API/model keys remain unchanged for repositories and tests.
- This is display-only polish.

## Validation

- Targeted widget validation passed with `flutter test
  test\etf_00631l_widget_test.dart`.
- Full validation passed: Flutter analyze/test/build, backend tests, release
  check with acceptable WARN-only output and `failures=0`, and
  `git diff --check`.
