# ETF research room v4.37 manual comparison default

v4.37 changes the ETF comparison default to match the selected ETF first.

## What Changed

- When a symbol is selected from the top-left search, the comparison panel starts with that ETF only.
- Other ETFs are added by manually toggling chips or by applying a category filter.
- The comparison text no longer implies that every comparison is anchored to 00631L.

## Why

ETF comparison should be user-selected. 00631L remains the first complete research room, but comparison mode should not force every selected ETF to be compared against 00631L.

## Scope

- UI state behavior and widget tests only.
- Does not change price history data, static export, live backend, TX live, or investment guidance.
