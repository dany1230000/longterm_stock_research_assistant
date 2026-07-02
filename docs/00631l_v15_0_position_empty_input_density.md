# 00631L v15.0 Position Empty Input Density

This release tightens the mobile position tab when no local position has been
saved yet.

## What Changed

- Phone width now combines the empty position input fields and the local save
  action into one compact card.
- The separate full-width save action is hidden only for the empty compact
  layout.
- Existing-position controls and wider layouts keep their previous structure.

## Product Boundary

- No position calculation change.
- No data-source change.
- No account sync or login change.
- Position data remains local-only unless the user exports it manually.

## Validation

Run the normal release checks:

```cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```
