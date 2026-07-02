# 00631L v11.7 position mobile entry

## Goal

Make the position page faster to use on phones by putting the input fields ahead
of secondary guidance text.

## Change

- Phone width hides the duplicate position input mini-header.
- Phone width hides the empty-position hint strip.
- Share and average-cost inputs remain visible, with JSON export and clear
  actions unchanged.
- Wider layouts keep the fuller guidance.

## Expected behavior

- Users can enter local-only position data with less vertical scrolling on
  phones.
- Position data still stays in browser local storage and is not sent to any
  external account service.
- No position calculation behavior changes.

## Verification

- Phone-width widget tests assert the long hint/header are absent while the
  primary position fields remain visible.
- Existing position tests still cover local-only save/export/clear controls.
