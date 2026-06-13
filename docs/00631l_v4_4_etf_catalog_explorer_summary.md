# 00631L lab v4.4 ETF catalog explorer summary

## Scope

v4.4 starts turning the TWSE all-ETF catalog into a visible ETF data entry point. It does not add full ETF comparison, investment guidance, notifications, or automated trading.

## Completed

- Added a dedicated `ETF` bottom navigation section.
- Added an ETF catalog page with row count, data time, source status, search, and simple filters.
- Added local filtering for common ETFs, Taiwan equity ETFs, high-dividend ETFs, leveraged/inverse ETFs, and all catalog rows.
- Moved the large ETF catalog preview out of settings.
- Settings now shows only ETF catalog status and comparison readiness.
- Updated the theme toggle label to show the current mode as `日間模式` or `夜間模式`.
- Added widget coverage for the ETF page, search behavior, navigation, and updated settings/theme wording.

## Data Boundary

The ETF catalog comes from the normalized TWSE all-ETF catalog endpoint when live backend data is available. Since v4.7, static public mode can also load an exported TWSE catalog snapshot. Mock fallback remains labeled as mock.

## Still Not Done

- Full ETF comparison workflow.
- ETF-specific history pages for every ETF.
- User-defined ETF watchlists.
- Investment guidance or trading actions.
