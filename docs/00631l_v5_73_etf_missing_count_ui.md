# 00631L v5.73 ETF Missing Count UI

Date: 2026-06-24

## Scope

v5.73 connects the static ETF history `missingCount` field through the Flutter
model, repositories, and ETF data-library UI.

## Changes

- `EtfOperationsStatus` now carries `etfPriceHistoryMissingCount`.
- Static and proxy repositories parse `missingCount` from
  `etf_price_history_index.json` or backend operations/status.
- Cached fallback paths preserve the missing-count value.
- ETF data-library completion totals use `readyCount + missingCount` when the
  backend provides an explicit missing count.
- Widget and repository tests cover the static missing-count mapping.

## User Impact

The ETF data-library panel now describes catalog coverage with direct counts:

- ready histories
- missing histories
- coverage tiers

Normal catalog gaps are shown as data coverage, not warning spam.

## Validation

Run:

```cmd
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```
