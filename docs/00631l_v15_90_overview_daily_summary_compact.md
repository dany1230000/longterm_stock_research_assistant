# 00631L v15.90 Overview Daily Summary Compact

## Scope

This release tightens the phone overview first screen by removing duplicate
daily fact cells below the chart.

## Changes

- The top compact ribbon remains responsible for DAY / NAV / HIS status.
- The daily summary card now shows a single compact AI readout plus TX / 2330 /
  CASH holdings chips.
- Repeated DAY / TX / 2330 cells were removed from the phone summary card.
- No data source, parser, holdings calculation, or backtest logic changed.

## Validation

- Widget coverage verifies the compact AI line is present, the old repeated
  daily fact rail is absent, and the holdings chips remain visible.
- Full release validation remains required before tagging this release.
