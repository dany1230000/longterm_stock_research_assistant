# 00631L lab v6.87 - overview summary status labels

## Goal

Remove raw status words from the overview first screen daily summary.

## Changes

- DAY/LIVE/HIS summary chips now use user-facing labels for unavailable,
  backend, static, cached, and error states.
- Known holdings errors display `不可用` and `錯誤` instead of raw English
  labels.
- Static/loading captions use short Chinese labels such as `每日`, `後端`, and
  `靜態`.

## Boundaries

- This is a display-only change.
- Data source selection, intraday refresh, price history, holdings, TX quote,
  and backtest calculations are unchanged.
- Raw source keys remain available in models, repositories, tests, and
  maintenance payloads.

## Validation

- Targeted widget tests cover known unavailable holdings and intraday pending
  summary states.
- Full validation passed:
  - `dart format --set-exit-if-changed .`
  - `flutter analyze`
  - `flutter test`
  - `flutter build web`
  - `py -m unittest discover -s backend\tests`
  - `scripts\00631l_release_check.cmd` reported WARN with `failures=[]`
  - `git diff --check`
