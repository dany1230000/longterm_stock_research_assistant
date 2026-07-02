# 00631L v12.7 symbol search result density

v12.7 tightens the left-top ETF search result rows.

## What changed

- The visible result row keeps only the primary information:
  - code
  - ETF name
  - ETF type
  - history-ready or catalog-only state
  - latest available price
- History metadata such as coverage tier and row count now lives under
  `更多資料`.
- Price basis and gap reason remain under `更多資料`.

## Why

The ETF selector is the app entry point for switching symbols. The main result
row should be easy to scan, while lower-priority data-quality details stay
available without crowding the list.

## Validation

- `flutter analyze`
- `flutter test`
- `flutter build web`
- `py -m unittest discover -s backend\tests`
- `scripts\00631l_release_check.cmd`
- `git diff --check`
