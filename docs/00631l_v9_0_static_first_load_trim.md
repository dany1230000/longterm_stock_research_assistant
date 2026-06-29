# 00631L v9.0 Static First Load Trim

Date: 2026-06-29

## Goal

Reduce the GitHub Pages static-public first load by keeping the first-screen
operations status on compact JSON only.

## What Changed

- `status.json` now carries compact ETF price-history readiness fields:
  - `etfPriceHistoryRowCount`
  - `etfPriceHistoryReadyCount`
  - `etfPriceHistoryGapDetailCount`
  - `etfPriceHistoryDataTime`
  - `etfPriceHistoryCoverageTierCounts`
  - `etfPriceHistorySourceContractCounts`
  - `etfPriceHistoryGapReasonCounts`
  - `etfPriceHistoryGapReasonSamples`
- The static Flutter repository reads operations status from `status.json` and
  `release.json` only.
- The full ETF catalog and ETF price-history index remain available for search,
  comparison, and detail views, but they are no longer pulled by operations
  status on the first screen.

## Data Truthfulness

- Static-public mode still represents published historical data, not live
  intraday NAV.
- Live intraday NAV still requires the public backend.
- Missing ETF history rows remain unavailable with a recorded reason; the app
  does not infer unavailable official data.

## Validation

- Backend tests cover the compact `status.json` fields.
- Flutter repository tests verify operations status does not request
  `etf_catalog.json` or `etf_price_history_index.json`.
- The normal release check keeps guarding static-public output and forbidden
  user-facing wording.
