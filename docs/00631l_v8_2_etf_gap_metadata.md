# 00631L lab v8.2 ETF gap metadata

v8.2 makes ETF search readiness more explicit.

## What changed

- `etf_catalog.json` now carries per-symbol price-history metadata from the
  static ETF history index.
- Search results can show why an ETF is catalog-only, for example:
  - official source returned empty data
  - source request failed
  - history has not been imported yet
- The UI still separates:
  - ETF catalog rows
  - ETFs with usable price history
  - ETFs that are visible but not ready for history, backtest, or comparison

## Data boundary

This does not fabricate missing history. If an ETF has no usable official price
history, the app keeps it catalog-only and shows the reason.

## Files

- Backend static export: `backend/app/static_export.py`
- Dart model/repository mapping:
  - `lib/models/leveraged_etf_lab.dart`
  - `lib/repositories/static_00631l_repository.dart`
  - `lib/repositories/proxy_00631l_repository.dart`
- Search UI: `lib/features/leveraged_etf_lab/leveraged_etf_00631l_screen.dart`

## Validation

Run:

```cmd
flutter test test\etf_00631l_proxy_repository_test.dart
flutter test test\etf_00631l_widget_test.dart
py -m unittest backend.tests.test_price_history_backtest
```
