# 00631L lab v3.9 mobile information architecture summary

v3.9 responds to the mobile UI review and makes the 00631L PWA behave more like a single-purpose market app.

## What Changed

- Removed the duplicate top section navigation.
- Kept bottom navigation as the single primary section switcher.
- Reduced the top header to the 00631L selector, app title, frontend mode, refresh, and theme toggle.
- Limited the large quote hero to the overview page only.
- Holdings, history, backtest, position, AI, and system sections now open directly into their own functional content.
- Replaced decorative mini chart icons in the market-focus board with clear data-type badges:
  - `DAY` official daily holdings
  - `LIVE` intraday NAV
  - `HIS` historical price
  - `AI` rule-based analysis
  - `SYS` maintenance status
- Increased bottom padding so the fixed bottom navigation does not cover content.

## Product Direction

The app remains mobile-first and focused on 00631L. The interface emphasizes data name, status, key value, and supporting detail instead of decorative icons.

## Data Boundaries

- Official holdings remain daily snapshots.
- Intraday NAV still requires the live backend.
- Static public data supports public history and backtest.
- Mock/fallback data remains labeled and is not presented as official.

## Non-Advice Boundary

The UI describes data state, historical changes, and app operations only.
It does not provide investment guidance or trading instructions.
