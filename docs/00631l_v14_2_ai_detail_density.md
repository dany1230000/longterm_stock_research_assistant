# 00631L v14.2 AI Detail Density

This release tightens the AI analysis page on phone width.

## What Changed

- The AI tab first screen now focuses on today's conclusion, compact DAY / LIVE / HOLD facts, the primary program action, and the `AI 資料細節` entry.
- The four-tile daily decision strip remains available, but it moves inside the expanded detail panel on compact phone width.
- Desktop and wider layouts keep the richer first-screen context.

## Product Boundary

- No data-source change.
- No TX live change.
- No investment guidance.
- AI output remains rule-based data interpretation.

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
