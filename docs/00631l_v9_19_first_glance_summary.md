# 00631L lab v9.19 first-glance summary

Date: 2026-06-29

## What changed

- The mobile quote header now includes a compact first-glance row: price, data, and history.
- The row sits above the existing quote readiness numbers, so users can identify the main information groups before reading details.
- The one-year overview chart remains visible in the first phone viewport.

## Why

The app should open like a focused ETF research tool, not a debug dashboard. The first screen now gives a clearer reading order without adding another large card.

## Verification

- Phone-width widget coverage confirms the new first-glance row is present.
- The same test still checks that the overview chart stays visible before the first viewport bottom.
- Existing forbidden wording and release checks remain unchanged.
