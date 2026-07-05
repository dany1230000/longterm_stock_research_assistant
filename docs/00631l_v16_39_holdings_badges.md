# 00631L v16.39 Holdings Badges

v16.39 removes internal-style holdings badges from the visible holdings cards.

## Changed

- `STK` is now shown as `股票`.
- `FUT` is now shown as `期貨`.
- `CASH` is now shown as `現金`.
- `OTHER` is now shown as `其他`.

The market codes `TX` and `2330` remain unchanged because they are actual
instrument identifiers, not decorative labels.

## Scope

This is a UI wording and readability change only. It does not change official
holdings parsing, weights, history, backtest, or source status behavior.
