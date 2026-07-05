# 00631L v16.22 History Header Labels

This release tightens the history and backtest first screen by clarifying the compact header labels.

## Scope

- History/backtest top strip now uses clear labels:
  - `區間`
  - `筆數`
  - `報酬`
  - `回撤`
  - `最新`
  - `來源`
  - `調整`
- Phone title now reads `00631L yyyy/MM/dd` without an extra separator.
- The history and backtest page still starts with compact range and metric context before deeper comparison content.

## What Did Not Change

- No price history data changed.
- No backtest calculation changed.
- No ETF comparison behavior changed.
- No TX live integration was added.
- No investment recommendation text was added.

## Validation

Targeted test:

```powershell
flutter test test\etf_00631l_widget_test.dart --plain-name "history range context wraps on phone width"
```
