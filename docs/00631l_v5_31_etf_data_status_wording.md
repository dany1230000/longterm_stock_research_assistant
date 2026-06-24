# 00631L lab v5.31 ETF data status wording

## Scope

v5.31 improves ETF data readiness wording in the mobile app. The change is
small but important: history-ready status means a symbol has usable historical
price data for charting, backtest, and comparison. It does not mean official
daily holdings history has been fully imported for that ETF.

## Changes

- Renamed the app section from `ETF 資料補齊` to `ETF 資料庫狀態`.
- Added wording that ready ETFs can support history, backtest, and comparison.
- Added wording that ready status does not imply official holdings history is
  complete.
- Kept live/static/mock source labels unchanged.

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
