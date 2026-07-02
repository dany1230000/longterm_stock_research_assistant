# 00631L v12.6 settings preference density

v12.6 tightens the `我的` page preference grid on phones.

## What changed

- The account, appearance, selected ETF, and local-position cards use a flatter
  2x2 layout on compact width.
- Preference cards keep the main status and short action visible without
  stretching the first screen.
- Advanced diagnostics remain behind the existing advanced sections.

## Scope

This release changes presentation only. Data mode, diagnostics, export,
deployment, and ETF readiness logic are unchanged.

## Validation

- `flutter analyze`
- `flutter test`
- `flutter build web`
- `py -m unittest discover -s backend\tests`
- `scripts\00631l_release_check.cmd`
- `git diff --check`
