# 00631L v12.8 overview AI glance density

v12.8 tightens the overview AI glance card.

## What changed

- Reduced padding and line spacing in the overview AI card.
- Kept the same content: one AI summary line, one program action, source label,
  time, and disclaimer.
- Tightened the phone first-screen height guard for the overview AI card.

## Why

The overview should lead with quote, chart, daily holdings context, and a short
AI interpretation without letting the AI card dominate the first screen.

## Validation

- `flutter analyze`
- `flutter test`
- `flutter build web`
- `py -m unittest discover -s backend\tests`
- `scripts\00631l_release_check.cmd`
- `git diff --check`
