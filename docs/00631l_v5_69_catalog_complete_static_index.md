# 00631L lab v5.69 catalog-complete static index

Date: 2026-06-24

## Scope

v5.69 makes the public static ETF price-history index account for every symbol in the TWSE ETF catalog.

## Changes

- Static Pages build now exports `--multi-etf-codes all-catalog`.
- `all-catalog` includes every catalog code in `etf_price_history_index.json`.
- ETF codes with saved price history remain ready and export their JSON files.
- Catalog codes without saved price history are retained in the index as `unavailable`.
- The public status can now show the true catalog gap instead of hiding missing symbols.

## Why

Previous static exports only indexed local ready history files. That kept the app usable, but made the catalog readiness denominator harder to verify. This release keeps the same usable data while making missing ETF histories explicit.

## Validation

Run:

```cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
scripts\00631l_build_pages_static.cmd
git diff --check
```
