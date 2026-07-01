# 00631L lab v9.79 comparison chart date detail

## Goal

Make ETF comparison charts clearer on mobile by showing the actual data date and
values instead of implying a fixed 00631L benchmark.

## Changes

- ETF comparison remains a user-selected basket.
- The comparison chart now stores the real source date for each plotted point.
- The touch detail panel now says `指定資料日` and shows values for the selected
  ETF basket.
- The chart shows start, middle, and end date labels below the chart.
- The wording keeps the comparison neutral: no fixed benchmark and no investment
  action wording.

## Validation

- Flutter widget coverage checks the comparison detail panel, date-axis labels,
  and neutral wording.
- Existing history, backtest, static data, and live fallback behavior remain
  unchanged.
