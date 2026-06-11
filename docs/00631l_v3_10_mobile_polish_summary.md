# 00631L lab v3.10 mobile polish summary

v3.10 continues the mobile-first UI cleanup after the information architecture pass.

## What Changed

- Bottom navigation now fits all seven sections on screen without horizontal scrolling.
- The selected bottom item has a compact highlight while inactive items stay quiet.
- Mobile tables now render as readable cards instead of wide data tables.
- Desktop and tablet widths still use the denser data table layout.
- Holdings, futures, cash, price history, and history summary rows keep the same data but are easier to scan on a phone.

## Product Direction

The app should feel like a dedicated 00631L market tool:

- one primary bottom navigation
- clear section-specific content
- fewer decorative elements
- data name, status, key value, and detail first

## Data Boundaries

- Official holdings remain daily snapshots.
- Intraday NAV still requires the live backend.
- Static public data supports public history and backtest.
- Mock/fallback data remains labeled and is not presented as official.

## Non-Advice Boundary

The UI describes data state, historical changes, and app operations only.
It does not provide investment guidance or trading instructions.
