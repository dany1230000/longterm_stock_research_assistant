# 00631L lab v9.60 - public loading shell polish

## Goal

The public PWA should feel like the same ETF research app before Flutter
finishes loading. The HTML loading shell is the first screen users see on
GitHub Pages, so it should not look like a debug placeholder.

## Changes

- Replaces English loading labels with user-facing Chinese labels.
- Uses `資料載入中`, `盤中 NAV`, `官方內容物`, `歷史回測`, and `AI 分析`.
- Keeps the bottom navigation preview aligned with the app pages.
- Adds a metadata test that prevents `ETF Research Room`, `loading data`,
  `LIVE`, `DAY`, or `HIS` from returning to the public loading shell.

## Scope

- No runtime data behavior change.
- No backend or parser change.
- No generated static data committed.
