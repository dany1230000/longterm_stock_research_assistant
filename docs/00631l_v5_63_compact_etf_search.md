# 00631L lab v5.63 compact ETF search

Release tag: `00631l-lab-v5.63-compact-etf-search`

## What changed

The left-top ETF search sheet now keeps only the practical selection controls
visible first:

- search field
- completion percentage
- history-ready count
- data gap count
- filter chips
- ETF and stock result list

Detailed catalog rows, full denominator, source labels, and coverage-tier counts
are still available under `資料細節`.

## Why

The selector should help users switch ETF context quickly. Diagnostic numbers are
useful, but they should not push searchable ETF results down the phone screen.

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
