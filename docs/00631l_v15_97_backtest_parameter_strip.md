# v15.97 backtest parameter strip

This release makes the history/backtest page shorter on phones by showing the
active backtest parameters in one compact strip.

## What changed

- The backtest section now shows strategy, initial amount, monthly amount,
  contribution day, and cost rate together before the expandable input form.
- Detailed amount and cost fields remain editable in the existing expansion
  panel.
- The strip helps users compare the currently active date range and backtest
  parameters without opening a tall form first.

## Guardrails

- Backtest calculations did not change.
- The default range remains the latest one year.
- Date controls remain visible and adjustable.
- The page still states that backtests do not represent future performance.
