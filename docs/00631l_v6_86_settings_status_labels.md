# 00631L lab v6.86 - settings status labels

## Goal

Make the account/settings, position, AI, and comparison surfaces read like a
finished app instead of exposing internal status keys.

## Changes

- The frontend mode label now displays as `即時後端`, `公開靜態`, or `示範資料`.
- Source/status badges map common internal keys to user-facing labels, such as
  `官方`, `快取`, `靜態官方`, `公開靜態`, `本機保存`, and `規則分析`.
- The position page uses `本機保存` instead of `local-only` in visible badges and
  descriptions.
- The AI page uses `規則分析` instead of `rule_based` in visible badges and
  summaries.
- Selected ETF capability badges now read `歷史可用`, `回測可用`, `比較可用`,
  and `AI 完整資料` when history is imported.
- Comparison readiness text now uses concise Chinese labels for candidate,
  comparable, and skipped rows.

## Boundaries

- Raw API/model keys remain unchanged for contracts, tests, and maintenance
  filters.
- This release does not change price history, holdings, intraday NAV, TX data,
  backtest formulas, or ETF import behavior.
- The app continues to avoid trading instructions and only describes data
  status.

## Validation

- Targeted widget tests covered position, AI/settings, and ETF data-library
  readiness.
- Full validation should still run before tagging:
  `dart format --set-exit-if-changed .`, `flutter analyze`, `flutter test`,
  `flutter build web`, backend tests, release check, and `git diff --check`.
