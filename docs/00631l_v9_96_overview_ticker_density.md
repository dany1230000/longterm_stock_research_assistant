# 00631L v9.96 overview ticker density

## Scope

This release tightens the overview first screen.

## Changes

- Removes extra spacing and one divider inside the mobile market stack.
- Makes the daily data ticker narrower and lower.
- Keeps the same facts visible: official holdings date, intraday NAV time, and
  historical data count.
- Keeps advanced source and maintenance details inside the `進階資料` expansion.

## Product Rule

The overview page must show price, premium/discount context, and the one-year
chart quickly. Source labels stay truthful, but technical details should not
dominate the first screen.

## Validation

- Widget tests guard the daily summary strip height on the overview first
  screen.
- Full release validation keeps tests, build, release check, and forbidden
  wording scan in the loop.
