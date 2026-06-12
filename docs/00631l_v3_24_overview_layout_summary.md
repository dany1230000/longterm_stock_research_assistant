# 00631L lab v3.24 overview layout summary

Completed date: 2026-06-13

## Scope

v3.24 tightens the mobile overview page so the first screen reads more like a focused stock app.

## Changes

- The overview now shows only the compact quote card, a short "today at a glance" panel, and a single "more views" expansion near the top.
- Full numeric comparison, data-source details, 7 / 30 day holdings changes, and lower-priority diagnostics are grouped under "more views" instead of filling the first screen.
- The loading shell now uses a shorter placeholder section to avoid making startup look heavier than it is.
- No data source, parser, backtest, position, TX, notification, or trading behavior changed.

## Data truthfulness

- Official holdings remain a daily Yuanta snapshot, not intraday holdings.
- Intraday NAV and premium / discount still require live backend connectivity.
- Static public data remains historical data for public Pages use and is not live intraday data.
- Mock and fallback states remain labeled as fallback states.

## Scope boundaries

- TX live is still intentionally not connected.
- The app remains scoped to 00631L.
- The UI wording remains descriptive and non-advisory.
