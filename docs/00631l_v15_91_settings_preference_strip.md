# 00631L v15.91 Settings Preference Strip

## Scope

This release reduces the phone settings first-screen height and keeps
maintenance details behind advanced panels.

## Changes

- Phone settings preference cards now render as one horizontal account-style
  strip instead of a 2x2 grid.
- Account, appearance, selected ETF, and local position status remain visible
  without showing deployment diagnostics first.
- Advanced ETF data, backend, backup, export, and app-store preparation panels
  remain collapsed by default.
- No backend, data source, parser, or calculation behavior changed.

## Validation

- Widget coverage verifies the phone settings preference strip exists, stays
  compact, and still contains all four preference cards.
- Full release validation remains required before tagging this release.
