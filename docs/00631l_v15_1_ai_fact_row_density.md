# 00631L v15.1 AI Fact Row Density

This release tightens the mobile AI first screen.

## What Changed

- DAY / LIVE / HOLD facts now stay in one compact row on phone width.
- The daily interpretation and primary program action appear sooner before the
  advanced detail panel.
- Wider layouts keep the existing three-column fact layout.

## Product Boundary

- No AI provider change.
- No external LLM integration.
- No data-source change.
- The AI summary remains rule-based and descriptive only.

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
