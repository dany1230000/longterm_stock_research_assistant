# 00631L lab v6.88 - overview holdings mix clarity

## Goal

Make the official holdings digest easier to read on the public mobile overview.

## Changes

- The overview holdings digest keeps the TX futures and TSMC tiles unchanged.
- The former combined `MIX` value is now an exposure-structure tile.
- Stock, futures, and cash/margin percentages are shown as separate rows.

## Boundaries

- This is a UI readability change only.
- Holdings parsing, official daily data, static public history, backtest
  calculations, and selected ETF behavior are unchanged.
- The tile remains a data-status display, not a recommendation.

## Validation

- Targeted widget test: overview holdings digest on phone.
- Full validation passed:
  - `dart format --set-exit-if-changed .`
  - `flutter analyze`
  - `flutter test`
  - `flutter build web`
  - `py -m unittest discover -s backend\tests`
  - `scripts\00631l_release_check.cmd` reported WARN with `failures=[]`
  - `git diff --check`
