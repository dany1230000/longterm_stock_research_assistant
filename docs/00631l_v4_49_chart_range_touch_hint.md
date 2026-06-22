# ETF research room v4.49 chart range touch hint

Date: 2026-06-22

## Scope

v4.49 improves chart readability on mobile.

## Changes

- Mini charts now show their visible date range in the default touch hint line.
- The existing tap behavior remains: tapping a chart point shows the exact selected date and value.
- This helps users understand the chart axis even when the bottom labels are compressed.
- This change is UI-only. It does not change historical data, split adjustment, performance calculation, or backtest logic.

## Verification

- Widget coverage verifies the history page shows the date range inside the chart touch hint.
- Existing chart date-axis and selected-detail tests remain active.
