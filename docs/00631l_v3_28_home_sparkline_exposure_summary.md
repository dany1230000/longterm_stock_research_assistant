# 00631L lab v3.28 home sparkline and exposure summary

Completed date: 2026-06-13

## Scope

v3.28 makes the overview first screen more app-like by using existing data visually.

## Changes

- Added a compact 60-day closing-price sparkline to the overview page.
- Added a compact official exposure panel for stock, futures, and cash / margin weights.
- The new panel uses existing static/live price history and official daily holdings data.
- No new external data source was added.

## Data notes

- The sparkline is historical close data; it is not live intraday price movement.
- The exposure panel is the official Yuanta daily holdings snapshot; it is not intraday holdings movement.
- Live intraday NAV remains separate and still depends on the public backend.

## Boundaries

- TX live is still not connected.
- The app remains focused on 00631L.
- No automated trading or brokerage integration was added.
