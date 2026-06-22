# ETF research room v4.50 selected search state

Date: 2026-06-22

## Scope

v4.50 fixes the left-top ETF search sheet selected-state behavior.

## Changes

- The search sheet now receives the currently selected ETF code from the app header.
- Search results mark the actual current ETF as `目前頁面`.
- The selected-result message is no longer hardcoded to 00631L.
- This change keeps 00631L as the complete research room while making ETF switching feedback truthful.

## Verification

- Widget coverage selects 0050, opens search again, and verifies 0050 is marked as the current page.
- Existing catalog-only and ready-history search tests remain active.
