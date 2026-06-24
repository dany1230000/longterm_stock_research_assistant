# 00631L lab v5.52 selected ETF overview dedup

v5.52 removes duplicated selected ETF readiness content from the overview.

## Changes

- The non-00631L overview now shows only the compact history-readiness strip.
- The larger readiness banner remains available where it is useful: the
  history/backtest page when an ETF has no imported history.
- The full selected ETF data-context card remains in the AI page.

## Why

The overview should keep quote, chart, data source, and selected ETF readiness
visible without repeating long explanatory blocks. Deeper explanations stay in
the AI and history areas.

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
