# 00631L v16.82 history range wording

## Scope

This pass polishes the history/backtest first screen so it reads like a product
surface instead of an internal data label.

## Changes

- The compact history top strip now uses `近1年` instead of `1Y`.
- The desktop history subtitle now describes the default range and adjusted
  close in Chinese.
- The range data note now uses `分割調整收盤` instead of an English internal
  label.
- Widget coverage guards that the compact top strip no longer exposes the old
  English labels.

## Non-goals

- No backtest calculation behavior changed.
- No new data source was added.
- No trading instruction or investment guidance was added.
