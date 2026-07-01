# 00631L lab v10.9 overview chart priority

## Goal

Make the mobile overview first screen feel more like a market page. The quote
and one-year price chart should appear before secondary data-status details.

## Changes

- Moved the one-year chart directly below the compact quote header.
- Moved the daily holdings / intraday / history ticker below the chart.
- Tightened embedded chart padding and chart height.
- Added a widget guard that verifies the chart appears above the daily ticker
  and stays within the first phone viewport.

## Scope

This is a layout-only pass. It does not change data sources, calculations,
history adjustment logic, TX live behavior, or comparison semantics.
