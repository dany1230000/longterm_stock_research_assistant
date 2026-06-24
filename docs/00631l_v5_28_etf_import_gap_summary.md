# 00631L lab v5.28 ETF import gap summary

## Scope

v5.28 improves the ETF price-history import status output. The status command now includes catalog count and completion gap, so daily maintenance can distinguish "history index fully ready" from "full catalog covered".

## Script behavior

`scripts\00631l_import_etf_price_history.cmd --status-only --summary-only` now reports:

- `catalogRowCount`
- `completionTotal`
- `completionGap`
- `catalogSymbols`
- `gap`

The compact summary line keeps validation status and adds the catalog gap.

## Data import observation

A recent full-catalog import was run with:

```cmd
scripts\00631l_import_etf_price_history.cmd --from-catalog --limit 0 --start-date 2026-06-01 --allow-partial
```

It completed with no hard failures. Some catalog symbols returned no TWSE STOCK_DAY rows for the recent window, so the app must keep showing them as not fully ready instead of treating them as completed.

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
