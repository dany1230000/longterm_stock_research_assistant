# 00631L v16.29 History Range Chip Density

This release tightens the phone history/backtest range controls.

## What Changed

- Compact phone range chips now use `1 年`, `3 年`, and `全部`.
- Desktop and wider layouts keep the fuller labels.
- The history and backtest date controls still use the same selected range.

## Guardrails

- Date selection behavior is unchanged.
- The default range remains one year.
- Charts, performance metrics, and backtest calculations are unchanged.

## Validation

- Widget coverage verifies compact range chips use the shorter phone labels.
- Existing history/backtest tests continue to verify date controls, chart labels,
  and backtest inputs.
