# 00631L v6.42 history range selection state

v6.42 makes the history/backtest date range controls easier to read on phones.

## What changed

- History and backtest range chips now show an active selected state.
- The default range remains latest one year.
- Users can still choose start and end dates manually.
- The available quick ranges remain latest one year, latest three years, and all data.
- Short verified history ranges are labeled as all data when the range spans the full available coverage.

## What did not change

- Historical price data was not recalculated.
- Split-adjusted close behavior was not changed.
- Backtest formulas and assumptions were not changed.
- Source labels remain explicit; static data is not presented as live intraday data.

## Validation

- Widget coverage verifies the history default one-year chip is selected.
- Widget coverage verifies the backtest all-data chip becomes selected after tapping it.
- The page still displays the active date summary and chart date context.
