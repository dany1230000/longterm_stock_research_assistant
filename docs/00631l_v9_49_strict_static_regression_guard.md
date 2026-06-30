# 00631L lab v9.49 - strict static regression guard

Date: 2026-06-30

## Goal

Prevent GitHub Pages from deploying older public static data when a new release
is built from a shorter local price-history cache.

## Change

- `scripts\00631l_guard_static_public_regression.cmd` now fails on static data
  regressions even when the local release tag differs from the public release.
- Regressions include:
  - local `coverageEnd` older than public `coverageEnd`
  - same `coverageEnd` but lower primary 00631L `rowCount`
  - lower multi-ETF ready count
- The release mismatch remains a warning, but it no longer downgrades a real
  data regression.
- Added `scripts\00631l_restore_public_price_history.cmd` so Pages builds can
  restore the already-deployed public 00631L `price_history.json` into the local
  primary history store before exporting new static data.
- GitHub Pages and local Pages build both restore primary 00631L public history
  before restoring multi-ETF public history.

## Why

v9.48 exposed a deployment path where public static data could move from
`2026-06-30` back to `2026-06-26` because release mismatch converted the
coverage regression into a warning. Static-public history is a user-facing data
contract, so coverage and row counts must not regress silently.

## Scope

This release changes deployment guards and static export preparation only. It
does not add TX live sourcing, notification features, automated actions, or
investment guidance.
