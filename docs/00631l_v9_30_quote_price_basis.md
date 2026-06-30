# 00631L lab v9.30 quote price basis

v9.30 makes the first-screen quote header clearer about price-history
correctness.

## What changed

- The 00631L quote readiness row now shows `價格欄位` directly on the first
  screen.
- The same row also shows `分割調整`, so users can tell whether history and
  backtest views are using adjusted price data.
- The less important backend connectivity chip was removed from the first
  screen and remains available through the account/settings area.

## Scope

This is a UI clarity update only. It does not change price-history rows,
split-adjustment calculations, holdings parsing, intraday NAV fetching, or
backtest math.
