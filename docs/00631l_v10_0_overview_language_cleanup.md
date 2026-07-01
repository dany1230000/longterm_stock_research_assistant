# 00631L v10.0 overview language cleanup

## Scope

This release keeps the overview page focused on the first read.

## Changes

- Renames the overview advanced disclosure from `進階資料` to `更多資料`.
- Updates the subtitle so users know the top of the overview is for quote,
  NAV, premium/discount, and the visible one-year chart.
- Keeps data source, integrity, comparison, and maintenance details available
  behind the disclosure.

## Product Rule

The overview should read like a stock app home screen. Primary market data and
the chart stay visible first; technical data provenance remains available but
does not compete with the first glance.

## Validation

- Overview widget tests verify the renamed disclosure and direct chart display.
- Full release validation remains required before publishing.
