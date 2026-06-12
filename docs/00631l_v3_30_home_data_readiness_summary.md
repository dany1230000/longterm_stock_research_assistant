# 00631L lab v3.30 home data readiness summary

Completed on 2026-06-13.

## Scope

v3.30 adds a compact data readiness strip to the overview first screen.

## Changes

- The overview now answers the common first-screen question: "is the data complete enough to read?"
- The readiness strip shows:
  - price history row count,
  - backtest availability,
  - official holdings date,
  - intraday NAV time when available.
- The strip is small and horizontal, so it does not compete with quote, sparkline, or exposure data.

## Data Behavior

- No new external data source was added.
- Static-public history remains usable without a live backend.
- Intraday NAV still requires live backend data when running outside local fallback.

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
