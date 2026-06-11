# 00631L lab v3.11 section summaries

v3.11 focuses on the mobile section entry experience. It does not change data sources, backend behavior, TX live status, or investment scope.

## What Changed

- Each bottom navigation page now starts with its own compact summary.
- Overview remains the only page with the large quote-style header.
- Holdings opens with official daily snapshot context, TX weight, TSMC weight, stock/futures exposure, and NAV.
- History opens with coverage, row count, latest close, cumulative return, and max drawdown.
- Backtest opens with key calculated result fields and the historical-data disclaimer.
- Position opens with local-only storage status, market value, cost, estimated gain/loss, and data time.
- AI opens with source, readiness, data time, summary count, action count, and non-advice label.
- System opens with frontend mode, backend connection, readiness, price row count, daily cycle, and persistence status.

## Product Direction

The app should feel like a dedicated mobile market tool:

- bottom navigation is the single section switcher
- every page has a purpose-specific top summary
- badges describe data type or source instead of decorative icons
- static_public, live_proxy, mock_default, stale, and error states stay visible without dominating the page

## Data Boundaries

- Official holdings are daily snapshots, not intraday holdings.
- Intraday NAV and premium/discount require live backend data.
- Static public data supports public history and backtest.
- Mock/fallback data remains labeled and is not presented as official.

## Non-Advice Boundary

The section summaries explain data status, historical changes, and app operations only.
They do not provide investment guidance or trading instructions.
