# 00631L v5.14 ETF Data Library Readiness

v5.14 makes multi-ETF data readiness visible in the app settings page.

## What Changed

- Added an `ETF 資料補齊` summary block near the top of settings.
- The summary shows:
  - catalog row count
  - history-ready count
  - long-term coverage count
  - recent coverage count
  - not-ready count
  - latest data time
- Added widget coverage for the readiness summary using the ETF history
  readiness fixture.

## Why It Matters

The app already has TWSE ETF catalog and multi-ETF price-history foundations.
This release makes that data state visible to normal users instead of hiding it
inside maintenance diagnostics.

## Data Scope

- No new data source is added.
- The readiness counts describe imported or static ETF price histories.
- 00631L remains the complete room for official holdings and intraday NAV.

## Safety

The block reports data availability only. It does not provide investment
guidance, account integration, forecasts, or automated actions.
