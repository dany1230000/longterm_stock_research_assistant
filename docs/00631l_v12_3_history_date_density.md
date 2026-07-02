# 00631L v12.3 history date density

v12.3 tightens the history and backtest date controls on phone screens.

## What changed

- The history/backtest date range selector keeps the same one-year default and
  start/end date actions.
- On narrow screens, preset chips now stay in a short horizontal row.
- Start/end date buttons hide lower-priority captions on phones.
- The range context card hides explanatory copy on phones and keeps only the
  title, status, key numbers, preset controls, and start/end date actions.
- Sparse history charts from v12.2 remain visible when only one point exists.

## Why

The previous phone layout spent too much vertical space on date controls before
the chart. This release keeps date selection usable while moving the chart and
backtest context higher on the screen.

## Validation

- `flutter analyze`
- `flutter test`
- `flutter build web`
- `py -m unittest discover -s backend\tests`
- `scripts\00631l_release_check.cmd`
- `git diff --check`

The release check may report acceptable WARN entries when external/public checks
are unavailable, as long as `failures=[]`.
