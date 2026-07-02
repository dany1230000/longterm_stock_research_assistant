# 00631L v11.6 history range density

## Goal

Make the history/backtest page shorter and easier to scan on phones.

## Change

- Phone width shows only the two most important range metrics in the range
  control card.
- The repeated inline date labels are hidden on phone width because the main
  range summary and date buttons already show the selected dates.
- Date buttons use tighter padding on phones.
- Desktop and wider layouts keep the fuller range context.

## Expected behavior

- History and backtest still default to the latest one-year range.
- Users can still pick start/end dates and switch one-year, three-year, or all
  data ranges.
- No backtest calculation or price-history data source behavior changes.

## Verification

- Phone-width widget tests assert compact range metrics and no duplicate inline
  date labels inside the history range panel.
- Existing history/backtest tests still verify date controls, charts, and
  non-advisory disclaimers.
