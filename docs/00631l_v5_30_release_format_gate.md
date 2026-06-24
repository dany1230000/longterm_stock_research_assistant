# 00631L lab v5.30 release format gate

## Scope

v5.30 moves the GitHub Pages Dart formatting requirement into the local release
check. This keeps the public Pages workflow and local validation aligned before
commit, tag, and push.

## Changes

- Added `dart format --set-exit-if-changed .` to `scripts\00631l_release_check.cmd`.
- Kept the v5.29 formatting output unchanged.
- Updated release metadata for `/health`.

## Why It Matters

GitHub Pages runs a format check before building the static PWA. If local release
validation does not run the same check, the app can pass local tests and still
fail the public workflow. v5.30 makes that mismatch visible locally.

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
