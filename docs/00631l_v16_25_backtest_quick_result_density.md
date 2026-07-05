# 00631L v16.25 Backtest Quick Result Density

This release shortens the phone backtest first screen.

## Scope

- Phone backtest quick result now shows the four core metrics: `期末`, `報酬`,
  `回撤`, and `波動`.
- Secondary metrics remain available in the full backtest area.
- The quick result no longer repeats source/disclaimer badges on phone width.
- The page still shows the backtest disclaimer below the controls.

## What Did Not Change

- No backtest calculation changed.
- No historical data source changed.
- No TX live integration was added.
- No investment recommendation text was added.

## Validation

Targeted test:

```powershell
flutter test test\etf_00631l_widget_test.dart --plain-name "backtest quick result stays compact on phone width"
```
