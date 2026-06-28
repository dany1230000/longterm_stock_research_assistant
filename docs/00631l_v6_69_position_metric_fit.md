# 00631L lab v6.69 position metric fit

v6.69 makes the local position account summary readable on phone width.

## What changed

- The position account summary uses a 2x2 metric layout on compact screens.
- Wider screens keep the previous horizontal layout.
- The summary still shows current ETF, market value, unrealized result, and
  local data status.
- Widget tests verify the phone-width summary labels stay inside the summary
  strip.

## Why

The previous fixed-width horizontal strip clipped the third metric on phone
screens. The new layout keeps related position values visible without requiring
horizontal scrolling.

## Scope

This is layout-only. It does not change:

- local-only storage,
- position calculations,
- JSON export or clear actions,
- quote source labels,
- backtest,
- AI analysis.
