# 00631L lab v3.21 compact home summary

Completion date: 2026-06-12

## Scope

v3.21 tightens the first screen so the public PWA reads more like a daily market app:

- The quote card now uses a compact price row and a horizontal facts strip instead of stacked metric boxes.
- Premium/discount explanation stays visible, but no longer makes the quote header tall.
- The overview page adds a concise holdings action row for latest official holdings exposure.
- The 7 / 30 day holdings change section is collapsed by default and keeps detailed rows available on demand.
- The homepage keeps `static_public`, `live_proxy`, `mock_default`, backend, holdings, and history status visible without a debug-dump layout.

## Non-goals

- No TX live connection.
- No expansion beyond 00631L.
- No trading instruction or investment guidance.

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
