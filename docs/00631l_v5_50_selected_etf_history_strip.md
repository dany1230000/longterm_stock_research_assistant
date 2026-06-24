# 00631L lab v5.50 selected ETF history strip

v5.50 makes the history/backtest page faster to scan after selecting another
ETF.

## Changes

- Added a compact selected ETF history-readiness strip above the history page.
- The strip shows:
  - selected ETF code
  - history source status
  - row count
  - coverage range
  - backtest readiness
  - live NAV scope
- The strip is shown only when the selected symbol is not 00631L, so the 00631L
  history page stays focused on its full research-room data.

## Why

Users can now switch the top-left symbol and immediately confirm whether the
selected ETF has enough verified history for history/backtest views without
opening deeper tables.

## Validation

Run:

```cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```
