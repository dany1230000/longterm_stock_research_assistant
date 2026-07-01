# 00631L lab v9.84 overview ticker density

## Goal

Make the overview first screen feel more like a mobile market app by reducing
the height of the daily data-status row.

## Changes

- Replaced the three mini status cards under the quote header with one compact
  horizontal ticker row.
- Kept the same facts visible: official holdings date, intraday NAV time, and
  historical price row count.
- Kept the one-year chart expanded and visible immediately below the compact
  status row.

## Validation

- Widget tests keep the overview daily summary strip under 48 px on phone
  width.
- Existing overview tests continue to verify the chart, holdings digest, and
  advanced details remain reachable.
