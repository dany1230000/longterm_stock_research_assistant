# ETF research room v4.47 compact position card

Date: 2026-06-22

## Scope

v4.47 shortens the position page on mobile.

## Changes

- The separate position status card is merged into the position input card.
- The single position card now contains local-only status, selected ETF source labels, input fields, estimate metrics, and save/export/clear actions.
- Local-only behavior remains unchanged: no login, no upload, and no repository-committed position data.
- This change is UI structure only. It does not change position calculation, storage format, selected ETF source logic, or backend behavior.

## Verification

- Widget coverage verifies the compact position card exists.
- Widget coverage verifies the old standalone position status card is no longer rendered.
- Existing local-only and non-advisory wording checks remain active.
