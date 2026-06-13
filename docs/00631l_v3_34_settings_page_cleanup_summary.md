# 00631L lab v3.34 settings page cleanup summary

Date: 2026-06-13

## Scope

v3.34 cleans up the bottom-right settings page. It does not change data sources, backend behavior, or trading scope.

## Changes

- The settings page now starts with a compact app/settings strip instead of a large system-status card.
- Account, appearance, and local-only position data are the first visible items.
- Data coverage is moved under `資料模式與完整度`.
- Backend, report, export, backup, and deployment diagnostics are moved under `進階維護診斷`.
- Widget tests verify that technical status rows are hidden until the user expands the relevant panel.

## User impact

The bottom-right page now feels like an app settings page rather than a diagnostics dashboard. General users see account/privacy and appearance first, while maintenance details remain available when needed.

## Boundaries

- No new data source is added.
- Static-public and live-proxy modes keep their existing labels.
- This release does not add trading guidance.
