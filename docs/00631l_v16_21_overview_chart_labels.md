# 00631L v16.21 Overview Chart Labels

This release improves the first-screen overview chart labels.

## Scope

- Renames the overview chart date-axis labels to clear labels:
  - `起點`
  - `中段`
  - `最新`
- Renames chart touch-detail labels to:
  - `日期`
  - `收盤`
- Keeps the one-year overview chart visible on the home screen.
- Keeps existing date touch detail behavior.

## What Did Not Change

- No historical data calculation changed.
- No split-adjustment logic changed.
- No backend source changed.
- No TX live integration was added.
- No investment recommendation text was added.

## Validation

Targeted test:

```powershell
flutter test test\etf_00631l_widget_test.dart --plain-name "overview chart shows one-year label and date axis"
```
