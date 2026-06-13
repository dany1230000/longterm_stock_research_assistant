# 00631L lab v3.46 first-screen and live-data clarity summary

Completion target: make the mobile first screen easier to scan and make public
backend maintenance status more truthful when official holdings are temporarily
unavailable.

## Changes

- The top app chrome stays compact and keeps the 00631L selector, app name,
  frontend mode, refresh, and theme toggle.
- The overview quote board is shorter: market price, premium/discount, intraday
  time, estimated NAV, previous NAV, price-history row count, and frontend mode
  are grouped together.
- The overview summary panel now uses `核心資料` and keeps AI/detail text below
  the first screen instead of crowding the first view.
- Remote backend maintenance now reports Yuanta holdings `unavailable` as WARN,
  not PASS. This is useful during Yuanta maintenance windows because price
  history and intraday NAV may still be usable.
- Public backend price history was refreshed with chunked remote maintenance:
  2828 rows, coverage 2014-10-31 to 2026-06-12.

## Scope

- No TX live connection.
- No expansion beyond 00631L.
- No notification or automated trading feature.
- No investment guidance. The UI describes data state and historical
  calculations only.

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

`scripts\00631l_remote_maintenance.cmd --mode daily` should return PASS or WARN
with `failures=[]`. WARN is acceptable when Yuanta official holdings are under
maintenance.
