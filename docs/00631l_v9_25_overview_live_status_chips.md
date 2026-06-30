# 00631L lab v9.25 overview live status chips

## Scope

v9.25 improves the overview update-time strip. The strip already showed daily
holdings, intraday NAV, TX, and history timing; this release makes each chip
show its source status directly.

## Changes

- Added visible status text inside each overview update-time chip.
- Added stable keys for update-time chips so phone layout regressions can be
  tested.
- TX without a live quote now shows `需 live backend` instead of a generic
  error label.
- TX with a valid quote continues to show the localized source status.

## Data Rules

- Official daily holdings remain a daily snapshot, not intraday content.
- Intraday NAV is live only when a live backend source is available.
- TX quote status is not inferred from holdings; missing TX quote data remains
  explicitly marked as backend-required.

## Verification

- Widget tests cover visible TX status in the overview update strip.
- Widget tests cover missing TX quote data and require the `需 live backend`
  label.
