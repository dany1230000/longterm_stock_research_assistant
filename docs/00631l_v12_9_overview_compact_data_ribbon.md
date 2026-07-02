# 00631L v12.9 overview compact data ribbon

v12.9 makes the overview first screen shorter and easier to scan on phones.

## What changed

- Replaced the separate phone daily-summary and holdings-digest strips with one
  compact data ribbon.
- The phone overview now keeps quote, one-year chart, DAY, NAV, TX, 2330, and
  history row count in one market stack.
- Desktop and wider layouts keep the fuller daily and holdings digest blocks.
- Widget tests now guard that the compact ribbon is used on phone width.

## Why

The first screen should behave like a market app: core quote, chart, data time,
and key holdings context must fit before secondary details.

## Validation

- `flutter analyze`
- `flutter test`
- `flutter build web`
- `py -m unittest discover -s backend\tests`
- `scripts\00631l_release_check.cmd`
- `git diff --check`
