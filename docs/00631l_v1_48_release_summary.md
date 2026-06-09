# 00631L lab v1.48 release summary

Completed on 2026-06-09.

## Scope

v1.48 reduces documentation sprawl by adding one primary documentation map.

## Changes

- Added `docs/00631l_docs_index.md`.
- Linked the new docs index from:
  - `README.md`
  - `backend/README.md`
  - `docs/00631l_maintenance_index.md`
- The docs index routes daily use, troubleshooting, maintenance, deployment, reports, scripts, and release summaries.

## Intended Use

Use `docs\00631l_docs_index.md` as the first document. Release summaries remain available for audit history, but daily operation should start from the daily usage, troubleshooting, maintenance, and deployment docs listed there.

## Limits

- No app feature was added.
- No TX live source was added.
- No notifications or investment guidance were added.

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
