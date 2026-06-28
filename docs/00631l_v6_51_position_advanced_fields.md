# 00631L v6.51 position advanced fields

v6.51 shortens the local position page form.

## What changed

- The visible position form now keeps the essential fields first: share count and average cost.
- Optional total-asset, fee, and note fields moved into an advanced position-fields panel.
- The account strip, local-only quick actions, JSON export, and clear behavior remain unchanged.

## Data behavior

- Position data remains local-only in the browser.
- Position calculations and JSON export payloads did not change.
- This page still shows estimates and data status only, not investment instructions.

## Validation focus

- Widget coverage verifies the essential fields are visible.
- The same test verifies optional fields are hidden before expansion and visible after opening the advanced panel.
