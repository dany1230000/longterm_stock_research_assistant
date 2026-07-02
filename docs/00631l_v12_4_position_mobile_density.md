# 00631L v12.4 position mobile density

v12.4 tightens the local position page on phone screens.

## What changed

- Empty local-position flow now keeps the save action as the only primary
  action on compact width.
- JSON export and clear actions stay available after a position exists, but no
  longer compete with the first empty input flow on phones.
- Source diagnostics are hidden from the phone first screen and remain available
  on wider layouts.
- Repeated estimate details are hidden on empty compact layouts because the
  account strip already shows the current estimated values.

## Data scope

Position data remains local-only in the browser. This release changes only the
layout hierarchy; it does not upload position data or change position
calculation logic.

## Validation

- `flutter analyze`
- `flutter test`
- `flutter build web`
- `py -m unittest discover -s backend\tests`
- `scripts\00631l_release_check.cmd`
- `git diff --check`
