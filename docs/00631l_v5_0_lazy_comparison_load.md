# v5.0 Lazy Comparison Load

## Scope

v5.0 improves public PWA startup behavior. The app no longer requests the
multi-ETF comparison history basket while the user is still on the overview
screen.

## Changes

- Overview keeps only the selected ETF's required context.
- ETF comparison histories load only after opening `歷史回測`.
- The existing comparison chart and basket controls remain available.
- Widget tests verify that overview does not create the comparison chart and
  that comparison requests increase after opening the history/backtest page.

## Why

Static public mode has many ETF history files. Loading comparison data before
the user opens the history/backtest page makes the first screen feel slower,
especially on mobile. Deferring the comparison basket keeps the first screen
focused on quote, chart, selected ETF, data correctness, and the official/static
source status.
