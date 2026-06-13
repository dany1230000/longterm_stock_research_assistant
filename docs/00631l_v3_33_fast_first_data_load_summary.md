# 00631L lab v3.33 fast-first data load summary

Date: 2026-06-13

## Scope

v3.33 improves first-screen loading behavior. It does not add a new data source and does not change the static-public or live-proxy contracts.

## Changes

- The app now waits for the fast lab provider before starting the full data provider.
- The first screen can render from quote, official daily snapshot, and lightweight status data before the full price history and deeper maintenance data load.
- Widget tests verify that full data loading is not requested while the fast provider is still pending.

## User impact

Opening the public PWA should feel less blocked by large historical/static data requests. The user sees the mobile app shell and first-screen status before deeper charts, history, AI, and maintenance data finish.

## Boundaries

- Static-public history and backtest remain available after full data finishes loading.
- Live intraday NAV still requires backend connectivity.
- This release only changes loading order and does not change analysis wording or trading behavior.
