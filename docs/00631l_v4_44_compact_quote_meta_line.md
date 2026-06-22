# 00631L lab v4.44 compact quote meta line

Date: 2026-06-22

## Scope

v4.44 reduces the height and visual noise of the overview quote header.

## Changes

- The quote metadata strip now renders as one compact horizontal text line instead of multiple pill boxes.
- The line keeps the core context: estimated NAV, session, and historical row count.
- Less-important caption detail is removed from the first screen; deeper source/status context remains in the lower detail sections.
- The change is presentation-only. It does not change official holdings, intraday NAV, static history, backtest, TX data, or local position calculations.

## Verification

- Widget coverage keeps the quote metadata strip present and asserts it stays compact.
- The overview chart still appears before `核心資料`.
- Existing source labels continue to distinguish live proxy, static public, mock, stale, and error states.
