# 00631L v9.97 history copy density

## Scope

This release tightens the history/backtest first screen.

## Changes

- Shortens the `價格歷史` section subtitle.
- Keeps the full coverage range in the compact top strip and date range panel
  instead of repeating it in another long sentence.
- Removes one duplicated vertical spacer before the performance metric grid.

## Product Rule

The history/backtest page should first show range, chart, and result context.
Detailed quality and source information remains available in expansions.

## Validation

- Widget tests guard the shorter history section copy.
- Full release validation keeps tests, build, release check, and forbidden
  wording scan in the loop.
