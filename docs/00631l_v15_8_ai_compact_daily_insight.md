# 00631L v15.8 AI Compact Daily Insight

This release makes the phone AI tab more useful before expanding details.

## What Changed

- Phone AI first screen now includes a compact "today focus" insight.
- The insight combines official daily holdings, premium/discount state, and historical sample count.
- Longer AI detail panels remain collapsed to keep the first screen short.

## Product Boundary

- No external LLM integration.
- No backend endpoint change.
- No trading instruction or forecast logic.
- This is a rule-based AI presentation improvement only.

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
