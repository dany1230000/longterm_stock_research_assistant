# 00631L lab v9.42 - defer full data load on overview

Date: 2026-06-30

## Goal

Reduce first-screen work on the public mobile PWA.

The overview page now renders from fast data first:

- live proxy quote / holdings / intraday NAV when available
- static `price_preview.json` for recent history context
- static status / release metadata

The larger full-data request is deferred until the user opens a tab that needs it:

- 歷史回測
- AI
- 設定

## Why

Before v9.42, the overview started `fetchLabData()` as soon as fast data returned.
That caused the public page to request full price history, catalog, holdings history,
operations status, and AI data even when the user only wanted the first screen.

Now the overview stays focused on the first-screen data path. Full data still loads
when needed, and refresh timers avoid full refreshes while the user remains on the
overview or position page.

## Verification

- Widget regression test: `overview defers full lab data until detail tab opens`
- Full release validation remains required before tagging:
  - `flutter analyze`
  - `flutter test`
  - `flutter build web`
  - `py -m unittest discover -s backend\tests`
  - `scripts\00631l_release_check.cmd`
  - `git diff --check`
