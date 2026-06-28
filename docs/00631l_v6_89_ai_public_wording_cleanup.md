# 00631L lab v6.89 - AI public wording cleanup

## Goal

Make the AI analysis first screen read like product copy instead of debug
output.

## Changes

- Added a display-only mapper for AI bullets and program-action text.
- User-facing AI text now maps common internal phrases to Chinese labels:
  - `static public mode` -> `公開靜態模式`
  - `rows` -> `筆`
  - `cached` -> `快取`
  - `public backend proxy` -> `公開後端`
- The AI fact card now shows historical row count as `筆` and source status as
  a localized label.

## Boundaries

- This is a display-only cleanup.
- Rule-based analysis logic, backend contracts, raw model keys, price history,
  holdings, intraday NAV, and backtest formulas are unchanged.
- The AI page remains descriptive and non-instructional.

## Validation

- Targeted widget test: AI and settings clean status wording.
- Full validation passed:
  - `dart format --set-exit-if-changed .`
  - `flutter analyze`
  - `flutter test`
  - `flutter build web`
  - `py -m unittest discover -s backend\tests`
  - `scripts\00631l_release_check.cmd` reported WARN with `failures=[]`
  - `git diff --check`
