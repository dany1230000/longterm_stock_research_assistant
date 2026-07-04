# 00631L v15.76 Chart Date Readability

## Scope

v15.76 improves the mobile chart date labels used by history, backtest, and
other shared line charts.

## Changes

- Phone chart axis labels now show `起點`, `中段`, and `終點` with full
  `yyyy/MM/dd` dates on separate lines.
- Chart touch details use compact spacing on phone width while keeping the
  selected date and value visible.
- Widget coverage now verifies full date labels and latest-date touch detail on
  the history/backtest page.

## Notes

- No data source, history calculation, or backtest engine behavior changed.
- The chart remains a historical data view. It is not a forecast and is not
  investment guidance.
