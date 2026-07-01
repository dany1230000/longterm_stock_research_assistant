# 00631L lab v9.85 history top compact

## Goal

Make the history/backtest page open faster visually on mobile by reducing the
height of the top context card.

## Changes

- Replaced the taller history/backtest intro card with a compact one-row header.
- Kept the selected ETF code, coverage range, row count, source status, and
  source contract visible.
- Kept date controls, the one-year default, charts, backtest, and comparison
  behavior unchanged.

## Validation

- Widget tests keep the history/backtest top strip under 56 px.
- Widget tests still cover the date controls, price chart, history metrics,
  backtest section, and ETF comparison section.
