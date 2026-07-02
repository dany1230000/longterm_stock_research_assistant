# 00631L v13.5 overview sparkline density

## Goal

Make the phone overview first screen show the one-year chart and compact data
ribbon sooner.

## Changes

- On compact phone width, the overview sparkline header now uses one row:
  title, latest price, and one-year change.
- The separate latest-price/date row is hidden on phones because the chart axis
  already carries date context.
- Wider layouts keep the full two-row chart summary.

## Validation

- Added a widget test that verifies the phone overview does not render the
  extra sparkline summary row.
- Existing overview tests still verify the chart, date axis, touch detail, and
  compact data ribbon.
