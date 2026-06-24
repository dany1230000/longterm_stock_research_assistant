# 00631L lab v5.49 selected ETF AI briefing

v5.49 makes the selected ETF AI page more analytical while staying rule-based.

## Changes

- Selected ETF AI bullets are generated from the selected ETF history summary.
- The AI page now describes:
  - history coverage and row count
  - latest trading day and daily movement
  - total return, drawdown, and annualized volatility
  - one-year range position
  - price field and split-adjustment context
  - live NAV mapping scope
- Added program-only action items for refreshing ETF history or adding future
  official source mapping.
- The selected ETF data-context card remains visible above the AI briefing.

## Scope

This release does not add new live data sources. Other ETFs still use imported
history and catalog data unless a verified live mapping is added later.

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

The briefing remains descriptive, rule-based, and non-advisory.
