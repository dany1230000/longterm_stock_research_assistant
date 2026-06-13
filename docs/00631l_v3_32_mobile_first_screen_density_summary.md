# 00631L lab v3.32 mobile first-screen density summary

Date: 2026-06-13

## Scope

v3.32 focuses on the mobile first screen. It does not add a new data source and does not change TX live behavior.

## Changes

- The overview page now keeps only the quote board and compact data readiness summary on the first screen.
- The 60-day price chart and official exposure bars moved behind a `圖表與曝險` expansion panel.
- Secondary comparison numbers, source details, and deeper diagnostics remain under `更多資料`.
- Widget tests now verify that the chart and exposure content are not visible by default on phone width.

## User impact

The public PWA opens faster visually and is easier to scan on mobile. The first view answers:

- current market price and premium/discount
- estimated NAV and previous NAV
- whether history, backtest, official holdings, and intraday NAV data are available
- whether deeper chart/source details are available without occupying the first screen

## Boundaries

- Static-public history and backtest remain available.
- Live intraday NAV still requires a reachable backend.
- This release keeps analysis text descriptive and does not add trading guidance.
