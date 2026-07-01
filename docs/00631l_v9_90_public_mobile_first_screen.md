# 00631L v9.90 public mobile first screen

## Scope

v9.90 tightens the public mobile overview screen.

## Changes

- Combines the quote header, daily source summary, and one-year chart into one
  market stack on the 00631L overview page.
- Keeps the overview chart expanded on first load.
- Removes repeated card borders from the first-screen quote/chart area.
- Keeps selected non-00631L ETF overview behavior unchanged.
- Adds a widget guard that the mobile overview renders the market stack and
  keeps the chart higher on a 390 px wide viewport.

## Data behavior

- No data source or parser behavior changed.
- Static public data, live proxy, and mock fallback labels remain separate.
- Official daily holdings remain daily snapshots. Intraday NAV still requires a
  live backend when not using static fallback.

## Product note

This is a layout polish release. It does not add TX live, broader ETF coverage,
notifications, or investment guidance.
