# 00631L lab v3.22 fast startup summary

Completion date: 2026-06-12

## Scope

v3.22 improves perceived startup speed for the public PWA:

- Adds a fast startup data path that fetches only first-screen essentials first.
- The app can show profile, official daily holdings snapshot, intraday NAV, and quote status before full history, AI, and operations data finish loading.
- Full lab data still loads in the background and replaces the fast snapshot automatically.
- If full details fail, the first screen remains visible with a clear fallback state instead of an empty page.
- The loading shell still appears when even the fast startup data is unavailable.

## Data Truthfulness

- Fast startup placeholders are labeled `deferred`.
- Static data is still static public history, not live intraday.
- Live intraday NAV still requires a reachable backend.
- This release does not add TX live and does not expand beyond 00631L.

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
