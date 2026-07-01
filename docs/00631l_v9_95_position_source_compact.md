# 00631L v9.95 position source compact

## Scope

This release tightens the position page first screen.

## Changes

- Keeps the position page focused on local position status and key account
  numbers.
- Moves market source, history source, and data-time chips into a `資料來源`
  expansion.
- Keeps local-only wording visible while reducing technical source noise on the
  first screen.

## Product Rule

The position page only estimates local position data from the selected ETF's
available market data. It does not upload personal position data and remains
non-advisory.

## Validation

- Widget tests guard that source chips are hidden until the `資料來源` expansion
  is opened.
- Full release validation keeps build, tests, release check, and forbidden
  wording scan in the loop.
