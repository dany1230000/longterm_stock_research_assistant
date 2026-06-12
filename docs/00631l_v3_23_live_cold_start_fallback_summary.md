# 00631L lab v3.23 live cold-start fallback summary

Completion date: 2026-06-13

## Scope

v3.23 reduces public-page startup delay when the live backend is cold or slow:

- `Cached00631LRepository.fetchFastLabData()` now gives the primary live source a short first-screen timeout.
- If the live proxy is slow, fast startup uses static/mock fallback immediately.
- Full lab data still loads through the normal path and can replace the fallback after the backend responds.
- The UI keeps showing a clear loading strip while full history, AI, and operations data are still loading.

## Why

GitHub Pages can be opened instantly from mobile, but a free public backend may cold start. The app should not keep the first screen blank while waiting for the backend.

## Data Truthfulness

- Fallback data remains labeled as fallback/static/mock/cached/deferred.
- Static public history is not live intraday NAV.
- Live intraday NAV still requires a reachable backend.
- No TX live, no all-leveraged-ETF expansion, and no investment guidance were added.

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
