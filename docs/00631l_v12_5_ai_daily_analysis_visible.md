# 00631L v12.5 AI daily analysis visible

v12.5 makes the AI page feel more like an analysis page instead of a source
detail panel.

## What changed

- The AI page now shows `當日資料判讀` before the detail expansion.
- The daily decision strip is visible without opening details:
  - 今日資料
  - 偏離判讀
  - 歷史資料
  - 後續操作
- The detail expansion now focuses on source readouts, matrices, and data
  completeness checks.

## Scope

The analysis remains rule-based. It describes data status, historical movement,
premium/discount state, and program actions only. It does not produce trading
instructions or future predictions.

## Validation

- `flutter analyze`
- `flutter test`
- `flutter build web`
- `py -m unittest discover -s backend\tests`
- `scripts\00631l_release_check.cmd`
- `git diff --check`
