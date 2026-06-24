# 00631L lab v5.59 compact backtest controls

Release tag: `00631l-lab-v5.59-compact-backtest-controls`

v5.59 makes the history/backtest page shorter on mobile while keeping the date
range controls directly available.

## What changed

- The large backtest result header was replaced by a compact `回測快覽` strip.
- Start/end date controls and quick range chips remain visible.
- Amount, monthly amount, monthly day, and fee inputs moved into
  `金額與成本參數`.
- Result cards, equity curve, drawdown curve, and the backtest disclaimer remain
  visible after the main controls.

## Boundaries

- Backtest math is unchanged.
- Historical data sources are unchanged.
- Backtest output remains historical analysis only and does not imply future
  results.
- No trading guidance was added.

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
