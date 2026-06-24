# 00631L lab v5.29 Pages format alignment

## Scope

v5.29 aligns the working tree with the GitHub Pages workflow formatting gate. The workflow runs `dart format --set-exit-if-changed .`, so local release validation now includes the same formatting expectation before the next public deployment.

## Changes

- Applied `dart format --set-exit-if-changed .`.
- Kept the v5.28 ETF import gap behavior unchanged.
- Updated release metadata so `/health` and the tagged release stay aligned.

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
