# 00631L lab v6.25 compact loading shell

v6.25 improves the first visible screen before and during Flutter startup.

## What changed

- Replaced the centered public web loading card with a compact mobile app shell.
- The loading shell now shows the 00631L symbol, app title, quote placeholder, data-source placeholders, and bottom navigation labels.
- The Flutter pending-data state now includes compact loading status, quote, metric, and section skeletons.
- Static public data, live backend data, and loading state remain clearly separated.

## Scope

- UI loading-state polish only.
- No ETF data calculation changes.
- No TX live changes.
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
