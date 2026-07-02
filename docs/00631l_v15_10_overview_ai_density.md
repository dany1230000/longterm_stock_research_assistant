# 00631L v15.10 Overview AI Density

This release makes the phone overview first screen less like a system console.

## What Changed

- Phone overview AI card now focuses on the daily summary line.
- Program operation text stays in the AI tab where detailed checks belong.
- The overview keeps the non-advice badge without using extra vertical space.

## Product Boundary

- No AI provider change.
- No backend endpoint change.
- No trading instruction or forecast logic.

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
