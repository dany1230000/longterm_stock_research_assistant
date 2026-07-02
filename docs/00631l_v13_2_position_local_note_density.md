# 00631L v13.2 position local-note density

v13.2 tightens the position page on phones.

## What changed

- Hid the local-only explanatory note from the empty phone position first
  screen.
- Kept the note visible on wider layouts or after a position exists.
- Added a stable widget key so tests can guard the compact empty state.

## Why

The empty position page should lead with the two primary inputs and save action.
Local-only storage is still true, but the first screen should not spend vertical
space on secondary explanation before the user has entered data.

## Validation

- `flutter analyze`
- `flutter test`
- `flutter build web`
- `py -m unittest discover -s backend\tests`
- `scripts\00631l_release_check.cmd`
- `git diff --check`
