# 00631L lab v6.29 position account strip

v6.29 makes the position page account summary more compact on phone screens.

## What changed

- The local-only position account metrics now render as a horizontal metric
  strip.
- Market value, unrealized P/L, symbol, and local position state stay visible
  without forcing a tall two-row metric grid.
- The local-only storage model, JSON export, clear flow, and calculations are
  unchanged.

## Scope

- Mobile layout polish only.
- No position calculation changes.
- No data upload, login, broker connection, or external account sync.
- No investment guidance.

## Validation

Run:

```cmd
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```
