# 00631L lab v5.55 compact position actions

v5.55 shortens the position page by moving local position actions near the
account summary.

## Changes

- The position page now shows a compact primary action bar directly under the
  local account summary.
- Save, JSON export, and clear actions no longer sit at the bottom of the input
  form.
- The page still keeps position data local-only and does not upload personal
  position data.

## Why

Mobile users should see account state and the main local data actions before
scrolling through the full input form.

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
