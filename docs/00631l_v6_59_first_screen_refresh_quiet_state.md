# 00631L lab v6.59 first-screen refresh quiet state

v6.59 reduces first-screen noise on the public mobile homepage.

## What changed

- The background-refresh banner is hidden when the first screen already has:
  - a usable quote value, and
  - either usable price history or a usable official daily holdings snapshot.
- Full-data error and fallback states still render the status strip.
- DAY / LIVE / HIS summary badges remain visible, so data source state is still clear.

## Why

The public app can show quote, history, and holdings context quickly while the
full live-proxy payload continues in the background. In that state, a large
banner took first-screen space without adding a necessary user action.

## Scope

This is a layout and status-display change only. It does not change:

- price history data,
- official holdings parsing,
- intraday NAV refresh,
- selected ETF behavior,
- backtest formulas,
- local position data,
- AI summary logic.
