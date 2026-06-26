# 00631L lab v5.76 comparison group polish

This release cleans up ETF comparison wording and keeps the history/backtest comparison experience focused on user-selected groups.

## What changed

- The history/backtest comparison panel now uses the user-facing term `比較組合` instead of the engineering term `basket`.
- Same-category chips remain quick-fill helpers only.
- The comparison context states that no ETF is treated as a fixed benchmark.
- Widget tests guard that the comparison panel no longer displays `basket` to users.

## Scope

- No TX live changes.
- No investment guidance.
- No changes to static generated data.
