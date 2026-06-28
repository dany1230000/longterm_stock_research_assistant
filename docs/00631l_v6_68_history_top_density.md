# 00631L lab v6.68 history top density

v6.68 further reduces the top height of the history/backtest page on phone
screens.

## What changed

- Removed the four repeated summary tiles from the top history card.
- Moved the `資料品質` expansion below the price-history chart block.
- Kept the range chips, current range summary, and chart near the top.
- Widget tests verify that `價格歷史` appears before `資料品質`.

## Why

The v6.67 layout brought the chart earlier, but the first screen still spent
too much height on duplicated summary and quality controls. This release keeps
the page focused on the chart first, then details.

## Scope

This is layout-only. It does not change:

- price history source data,
- split-adjusted close calculations,
- backtest formulas,
- selected ETF behavior,
- local position tracking,
- AI analysis.
