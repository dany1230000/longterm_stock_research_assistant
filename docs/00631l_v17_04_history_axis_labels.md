# 00631L v17.04 history axis labels

v17.04 makes chart date labels easier to understand on the history page.

## Changes

- History chart axis labels now use `開始`, `中段`, and `結束`.
- The labels match the current date-range mental model better than the old
  one-character abbreviations.
- The overview chart already used clearer labels, so this aligns history chart
  wording with the rest of the app.

## Scope

This release only changes visible chart axis labels and widget assertions. It
does not change chart data, date range calculation, backtest results, or price
history storage.
