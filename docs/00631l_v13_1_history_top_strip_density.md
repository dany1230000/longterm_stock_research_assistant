# 00631L v13.1 history top strip density

v13.1 tightens the history/backtest first screen on phones.

## What changed

- Removed the repeated coverage subtitle from the phone history top strip.
- Kept ETF code/name, source status, latest value, row count, status, and
  adjustment context in the compact metrics row.
- Coverage remains visible in the date-range card directly below the strip.
- Tightened the phone widget height guard for the history top strip.

## Why

The history/backtest page should show the date controls, chart, and backtest
inputs sooner. Coverage was already present in the range controls, so repeating
it in the top strip made the page feel longer without adding new information.

## Validation

- `flutter analyze`
- `flutter test`
- `flutter build web`
- `py -m unittest discover -s backend\tests`
- `scripts\00631l_release_check.cmd`
- `git diff --check`
