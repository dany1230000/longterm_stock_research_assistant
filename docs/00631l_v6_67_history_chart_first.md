# 00631L lab v6.67 history chart-first layout

v6.67 makes the history/backtest phone page easier to scan by moving the chart
before detailed date controls.

## What changed

- The history page now shows range chips, current range summary, and price
  charts before the detailed start/end date controls.
- Detailed start/end date controls are grouped under `日期設定`.
- The history top badge row removes duplicate labels such as `00631L / 00631L`.
- Widget tests verify the price chart appears before date settings.

## Why

The previous phone first screen spent too much space on date inputs before the
user saw the price chart. The new order makes the page read more like a mobile
market app: scan the chart first, then adjust parameters.

## Scope

This release only changes layout and labels. It does not change:

- price history data,
- split-adjusted close calculations,
- backtest formulas,
- official holdings parsing,
- intraday NAV,
- position tracking,
- AI analysis.
