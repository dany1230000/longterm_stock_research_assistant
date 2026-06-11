# 00631L lab v3.6 app UI refresh summary

Completed date: 2026-06-11

## Scope

v3.6 refreshes the 00631L PWA interface toward a mobile-first stock app layout.

The data contracts, backend endpoints, static fallback, live proxy, history, backtest, position tracking, AI summary, and system status behavior remain unchanged.

## UI changes

- Rebuilt the top quote area as a focused market card.
- Added a stronger visual hierarchy for:
  - 00631L name
  - market price
  - estimated NAV
  - previous NAV
  - premium/discount
  - data time
  - frontend mode
  - source status
- Reworked section navigation into a horizontal app-style segmented bar.
- Kept mobile-first spacing and constrained desktop width.
- Preserved dark mode support.
- Preserved text status labels so the page does not rely on color alone.

## Design references

The layout follows common public stock-app patterns:

- quote-first header
- compact status pills
- horizontal section navigation
- card-based detail sections
- explicit data freshness labels

No third-party branding, icons, or proprietary visual assets were copied.

## Validation

The redesigned screen is covered by existing widget tests:

- root opens the 00631L app
- mobile width renders without crashing
- quote header renders required market labels
- history, backtest, position, AI, and system sections remain reachable
- dark mode toggle remains available
- forbidden wording scan remains part of release check

## Boundaries

This release does not change investment logic, data parsing, backend contracts, or public deployment behavior.
