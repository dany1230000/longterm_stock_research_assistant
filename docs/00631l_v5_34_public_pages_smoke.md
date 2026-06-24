# 00631L lab v5.34 public Pages smoke check

## Scope

v5.34 adds a public GitHub Pages smoke check for the 00631L PWA. The check
verifies that the deployed root page still looks like the Flutter app, that the
PWA manifest identifies the 00631L app, and that static public data is present
with a usable row count and coverage range.

## Changes

- Added `scripts\00631l_check_public_pages.cmd`.
- Added `backend/scripts/check_public_pages_00631l.py`.
- Added public Pages smoke validation to `scripts\00631l_release_check.cmd`.
- Added backend tests for pass, fail, and network-unavailable outcomes.
- Updated backend release metadata to `00631l-lab-v5.34-public-pages-smoke`.

## Data Notes

This release does not change ETF pricing, holdings, intraday NAV, TX quote
sourcing, backtest calculations, or position tracking. It only adds a public
deployment smoke gate for the already deployed static PWA and static official
price-history export.

Network errors are reported as WARN so local release checks do not fail only
because GitHub Pages is temporarily unreachable. Invalid static payloads, too
few rows, missing coverage, or a non-00631L manifest are FAIL.

## Validation

Run:

```cmd
scripts\00631l_check_public_pages.cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```
