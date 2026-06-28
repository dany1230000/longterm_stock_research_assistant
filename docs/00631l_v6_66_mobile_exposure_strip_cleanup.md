# 00631L lab v6.66 mobile exposure strip cleanup

v6.66 removes the duplicated official-exposure strip below the overview chart
on phone-width screens.

## What changed

- The phone overview chart now shows only the price trend.
- Official holdings remain visible in the dedicated digest card below the chart.
- The wider desktop layout can still show the side-by-side exposure panel.
- Widget tests verify that the phone overview keeps the holdings digest and
  hides the narrow exposure strip.

## Why

When live official holdings were available, the chart panel showed a long
single-line exposure strip. On phone width it duplicated the next holdings card
and clipped the right-side cash text.

## Scope

This is a phone layout cleanup only. It does not change:

- holdings calculations,
- Yuanta parsing,
- price history,
- intraday NAV,
- backtest,
- position tracking,
- AI analysis.
