# 00631L lab v3.31 mobile quote trim and holdings fallback summary

Completed on 2026-06-13.

## Scope

v3.31 reduces first-screen visual noise on mobile and improves holdings fallback behavior during source format drift.

## Changes

- The mobile top bar now shows only the 00631L pill and app controls.
- The full app title remains available on wider screens.
- The quote card now keeps only the most important intraday facts:
  - market price,
  - premium/discount,
  - estimated NAV,
  - previous NAV.
- Lower-priority reference numbers remain available in deeper sections instead of occupying the first screen.
- If the live Yuanta ratio page cannot be parsed but local official holdings history exists, backend holdings and smoke checks now return `sourceStatus: cached` with an explicit error message.
- Daily cycle treats that state as WARN instead of FAIL, so the app remains usable while clearly showing the fallback.

## Data

- No new data source was added.
- Cached holdings fallback does not pretend to be official live data.

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
