# 00631L lab v3.36 overview history performance summary

Date: 2026-06-13

## Scope

v3.36 improves how complete historical data is surfaced on the overview page. It does not change historical calculations or add a new data source.

## Changes

- The `今日一眼看` metric strip now includes `歷史績效`.
- The metric shows cumulative historical return and maximum drawdown from the existing price history model.
- Widget tests verify that the overview and phone layout expose this historical performance entry.

## User impact

Users can confirm that historical data is available and see a key long-term performance/risk summary without opening the history/backtest page.

## Boundaries

- Historical figures remain backward-looking calculations.
- Backtest and history details remain in the history/backtest tab.
- This release does not add forecasts or trading guidance.
