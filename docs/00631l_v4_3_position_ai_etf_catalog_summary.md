# 00631L lab v4.3 position, AI, and ETF catalog summary

## Scope

v4.3 focuses on app usability. It does not change trading scope and does not add investment guidance.

## Completed

- Position page now starts with a clear local-only status panel.
- Position page shows an empty state before the user enters shares and average cost.
- Position result cards are grouped as market value, cost, unrealized P/L, and portfolio weight.
- AI page now separates source/readiness, daily signals, bullets, action items, and full-data briefing.
- Settings page now prioritizes account/privacy, appearance, local position data, and the ETF catalog.
- App/store preparation and maintenance diagnostics remain available but are collapsed by default.
- Frontend now has an `EtfCatalog` model and repository mapping for `/api/etf/catalog`.
- Mock mode includes a small ETF catalog fixture for UI fallback.
- Static public mode truthfully marks ETF catalog details as backend-required.

## ETF Catalog Direction

TWSE `all_etf.txt` is now exposed to the frontend through `EtfCatalog`. This is the first data foundation for future ETF comparison. The current 00631L research room remains focused on 00631L; broader ETF comparison is intentionally a later feature.

## Still Not Done

- Full ETF comparison workflow.
- User-defined ETF watchlists.
- All-ETF holdings pages.
- Investment guidance or trading actions.
