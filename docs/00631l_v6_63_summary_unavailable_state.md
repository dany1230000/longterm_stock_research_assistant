# 00631L lab v6.63 summary unavailable state

v6.63 makes the overview DAY/LIVE/HIS summary row clearer when a data source
already reports a final unavailable or error state.

## What changed

- DAY now shows `unavailable` with the source status when holdings are known to
  be unusable.
- LIVE uses the same rule when an intraday NAV response explicitly reports
  error or unavailable.
- Background wording such as `syncing` and `checking` is reserved for sources
  that are still waiting for detail data.
- Widget tests cover fast startup with a known holdings error.

## Why

The public mobile page could show a holdings error card while the summary chip
still said `syncing`. That made a confirmed source problem look like a normal
loading state.

## Scope

This is a display-state fix only. It does not change:

- official holdings parsing,
- intraday NAV fetching,
- price history,
- backtest formulas,
- position tracking,
- AI analysis.
