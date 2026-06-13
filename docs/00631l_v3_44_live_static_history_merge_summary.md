# 00631L lab v3.44 live/static history merge summary

Completed: 2026-06-13

## Scope

v3.44 improves public mobile data completeness when the live backend is
connected but has not yet accumulated full price history.

## Changes

- Keeps live proxy as the first source for profile, holdings, intraday NAV, and
  operations status.
- Uses static public price history when live backend price history is empty or
  unavailable.
- Merges static public price-history readiness into operations status while
  preserving live backend connection details.
- Keeps history/backtest usable on GitHub Pages even when the public backend
  volume is new or missing historical rows.

## Data Behavior

- Live intraday NAV still requires the public backend.
- Static public history remains the fallback for historical price and backtest
  data.
- Static public history is labeled as `static_official`; it is not labeled as
  live intraday data.

## Validation

- Repository tests cover live backend empty price history falling back to static
  public history.
