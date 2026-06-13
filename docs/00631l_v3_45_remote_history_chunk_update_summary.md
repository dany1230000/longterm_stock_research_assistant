# 00631L lab v3.45 remote history chunk update summary

Completed: 2026-06-13

## Scope

v3.45 makes public backend daily maintenance safer for Render and similar
platforms by avoiding one large full-history update request.

## Changes

- Remote maintenance now updates price history in chunks.
- If the backend has no complete listing-date coverage, it seeds from
  2014-10-31 by calendar year.
- If the backend already has complete listing-date coverage, it updates only a
  recent 45-day window.
- The existing `history_update` maintenance step now returns aggregate chunk
  status, saved row count, coverage, and final row count.

## Public Backend Result

The Render backend was seeded successfully after this change:

- rowCount: 2828
- coverage: 2014-10-31 to 2026-06-12
- `scripts\00631l_remote_maintenance.cmd --base-url https://longterm-stock-research-assistant.onrender.com --mode daily --timeout-seconds 180` returned PASS.

## Notes

This does not change the user-facing investment scope. It only improves public
backend data maintenance and keeps static public fallback available.
