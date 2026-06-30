# 00631L lab v9.32 compact quote height

v9.32 tightens the mobile quote header height after the first-screen strip
cleanup.

## What changed

- The quote header height guard is now `118px` in the phone-width widget test.
- The readiness row uses two-line chips instead of three-line chips.
- The premium/discount box has tighter padding so the chart starts earlier on
  the first screen.

## Scope

This is a layout-density update only. It does not change live data, static
history rows, split-adjusted price calculations, holdings data, or backtest
results.
