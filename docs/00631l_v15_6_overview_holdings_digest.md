# 00631L v15.6 Overview Holdings Digest

This release restores a concise holdings digest to the phone overview screen.

## What Changed

- Phone overview now shows the official daily holdings highlight below the AI glance.
- TX, TSMC, and exposure structure are visible without opening another tab.
- The exposure structure card uses a full-width mobile row to avoid cramped or broken labels.

## Product Boundary

- No holdings parser change.
- No holdings source change.
- No intraday NAV or TX live change.
- This is a phone information-architecture and layout improvement only.

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
