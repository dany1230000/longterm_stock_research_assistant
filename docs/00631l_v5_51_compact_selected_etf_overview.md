# 00631L lab v5.51 compact selected ETF overview

v5.51 keeps the selected ETF overview shorter on mobile.

## Changes

- Replaced the full selected ETF data-context card on the overview page with
  the compact history-readiness strip.
- The overview now keeps quote, chart, source status, and selected ETF readiness
  closer to the first screen.
- The full selected ETF data-context card remains on the AI page, where users
  expect a deeper explanation.

## Why

The overview should stay fast to scan. Detailed source and limitation text is
still available, but it now lives in the AI section instead of expanding the
home screen.

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
