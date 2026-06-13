# 00631L lab v3.42 web loading shell summary

Completed: 2026-06-13

## Scope

v3.42 improves the first visible state before Flutter finishes booting.

## Changes

- Adds a lightweight HTML loading shell in `web/index.html`.
- Shows the 00631L app title immediately on public web/PWA load.
- Explains that static public data can support history/backtest while live
  intraday NAV and latest official holdings require backend connectivity.
- Removes the shell after Flutter emits `flutter-first-frame`.

## Notes

This release does not change data sources or backend behavior. It reduces the
blank-page feeling during Flutter web startup.
