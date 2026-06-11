# 00631L lab v3.8 market app UI summary

v3.8 refreshes the 00631L PWA toward a mobile stock-app layout inspired by common market-screen patterns.
It does not copy a specific product brand, asset, or proprietary design.

## What Changed

- The 00631L lab now uses a dedicated market-dark visual shell.
- The top of the screen includes:
  - 00631L selector pill
  - compact primary tabs
  - refresh and theme controls
  - current frontend mode
- A market-data strip highlights:
  - official holdings status
  - premium/discount status
  - overall data status
- The overview includes a dense market-focus board with rows for:
  - official holdings
  - intraday NAV
  - price history
  - AI summary
  - daily maintenance
- Mobile now has a bottom navigation bar for the 00631L sections.
- Existing quote header, complete-data panels, history charts, backtest, position tracking, AI summary, and system status remain available.

## Data Boundaries

- Official holdings remain daily snapshots.
- Intraday NAV still requires the live backend.
- Static public data still supports history and backtest.
- Mock/fallback data remains labeled and is not presented as official.

## Non-Advice Boundary

The UI describes data state, historical changes, and app operations only.
It does not provide investment guidance or trading instructions.
