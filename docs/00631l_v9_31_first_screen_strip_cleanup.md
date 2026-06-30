# 00631L lab v9.31 first-screen strip cleanup

v9.31 removes a redundant first-screen label strip from the overview quote
area.

## What changed

- The decorative `行情 / 資料 / 歷史` row was removed from the mobile overview.
- The quote header now moves directly from price and premium/discount into the
  actionable readiness row.
- The one-year chart starts higher on the screen without changing chart data or
  calculations.

## Scope

This is a layout cleanup only. It does not change holdings, intraday NAV,
historical prices, split-adjustment handling, or backtest calculations.
