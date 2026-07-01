# 00631L lab v9.63 overview one-year window

v9.63 aligns the overview chart data window with its label.

## Changes

- The `近一年走勢` overview sparkline now filters price-history points from the
  latest available date back one year.
- Sparse histories still keep at least the latest two points so the chart does
  not disappear.
- The widget test now rejects an older out-of-window date on the overview
  sparkline axis.

## Scope

- This only changes the compact overview chart window.
- Full history and backtest date controls remain unchanged.
