# 00631L v15.3 Settings Summary Density

This release tightens the settings tab first screen on phones.

## What Changed

- Phone width settings now open with a shorter account-style summary.
- The summary keeps essential mode badges and a single data-mode line.
- Technical diagnostics remain inside the advanced settings panel.

## Product Boundary

- No settings persistence change.
- No backend or data-source change.
- No account login or sync change.
- This is a phone layout density improvement only.

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
