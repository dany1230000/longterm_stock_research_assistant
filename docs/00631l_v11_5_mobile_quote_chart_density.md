# 00631L v11.5 mobile quote chart density

## Goal

Make the phone first screen feel more like a market app by shortening the
overview quote chart stack without hiding the chart.

## Change

- Phone width now uses a compact one-year sparkline height.
- The date axis and touch detail row use tighter spacing on small screens.
- Wider layouts keep the previous chart height and spacing.

## Expected behavior

- The quote, one-year chart, data time strip, and official holdings digest fit
  higher on the first screen.
- The chart still supports touch detail for the selected date and value.
- This is a visual density release only; data source labels and calculations are
  unchanged.

## Verification

- Phone-width widget tests assert compact chart, date-axis, and touch-detail
  heights.
- Full Flutter/backend/release validation should continue to pass before tag.
