# 00631L lab v4.43 chart-first overview

Date: 2026-06-22

## Scope

v4.43 makes the overview first screen more chart-first.

## Changes

- The overview now shows the compact quote header followed immediately by the price/exposure chart panel.
- `核心資料`, data-quality details, holdings digest, and lower-priority detail panels stay below the chart.
- The chart panel remains always visible on the overview page; it is not hidden behind an expansion control.
- The change is UI order only. It does not change live data, static data, holdings parsing, backtest calculation, TX live handling, or portfolio logic.

## Reasoning

The first screen should answer the fast daily question first: current quote context and recent price/exposure movement. Operational and source details remain available, but they no longer push the chart below several cards.

## Verification

- Widget coverage asserts that `近一年走勢` appears before `核心資料` on the overview.
- Existing status labels still distinguish live proxy, static public data, mock, stale, and error states.
- The wording remains descriptive and non-advisory.
