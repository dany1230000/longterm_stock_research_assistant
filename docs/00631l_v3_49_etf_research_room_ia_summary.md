# 00631L v3.49 ETF research room IA summary

Completed date: 2026-06-13

## What Changed

- Product direction is now framed as an ETF research room, with 00631L as the active dedicated room.
- The user-facing bottom navigation was simplified to:
  - 總覽
  - 歷史回測
  - 持倉
  - AI
  - 設定
- The standalone 內容物 tab was removed from the main navigation.
- Official daily holdings highlights now live in 總覽:
  - TX 期貨
  - 台積電現股
  - 股票 / 期貨 / 現金
  - official tradeDate
- The history/backtest page now exposes start and end date selectors in the backtest form.
- AI copy now focuses on today:
  - official holdings date
  - intraday NAV data time
  - premium/discount deviation
  - holdings exposure
  - maintenance state

## Data Wording

- Holdings remains official daily snapshot data.
- Intraday NAV remains the live/cached backend-driven data source.
- Static-public history remains suitable for public history and backtest views.
- Color cues describe data state and price deviation only.
- The UI remains non-advisory and does not use trade-command wording.

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
