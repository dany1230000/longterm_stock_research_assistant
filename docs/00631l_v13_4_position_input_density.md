# 00631L v13.4 position input density

## Goal

Make the phone position page focus on the first useful action: enter shares,
enter average cost, then save local data.

## Changes

- On compact phone width with no saved position, the optional total-assets,
  fee, and note fields are hidden from the first screen.
- The optional fields remain available after a local position exists and on
  wider layouts.
- The shares and average-cost inputs stay in one compact row on phone width.
- Local-only storage behavior is unchanged.

## Validation

- Added a widget test that verifies the compact phone input row and hidden
  optional fields in the empty-position state.
- Existing position tests still cover local save/export/clear controls and
  advanced fields on wider layouts.
