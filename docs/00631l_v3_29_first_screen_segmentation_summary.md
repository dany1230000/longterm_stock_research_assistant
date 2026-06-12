# 00631L lab v3.29 first-screen segmentation summary

Completed on 2026-06-13.

## Scope

v3.29 improves the phone-first app layout without changing data sources.

## Changes

- The overview now shows the quote board, 60-day price sparkline, and official exposure bars before secondary details.
- The `今日一眼看` panel is now a compact horizontal summary instead of a taller grid.
- The history/backtest tab now uses an in-page switch:
  - `歷史` shows coverage, performance metrics, charts, and tables.
  - `回測` shows backtest inputs, summary, and curves only after selected.
- Top padding and quote board typography were tightened to reduce first-screen height.

## Data

- No new data source was added.
- Static-public price history and live backend fallback behavior remain unchanged.
- Official daily holdings remain daily snapshots.

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
