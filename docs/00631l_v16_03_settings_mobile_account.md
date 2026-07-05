# 00631L v16.03 Settings Mobile Account

## Scope

v16.03 keeps the right-bottom settings page focused on account-style daily use.
The first phone screen now favors short labels for:

- account state
- appearance preference
- selected ETF
- local position data

Technical maintenance details remain available under advanced settings, but they
do not appear on the first settings screen.

## UI Behavior

- The settings account block uses a compact phone header.
- Long explanatory text is hidden on phone width.
- Backend, deployment, export, backup, report, and data-integrity diagnostics
  stay inside advanced panels.
- Desktop keeps the fuller explanatory copy.

## Data Scope

No data source behavior changed. Live proxy, static public data, mock fallback,
local-only position data, and source labels remain unchanged.

## Validation

The widget test verifies that the phone settings first screen keeps technical
diagnostics collapsed and does not render long account/appearance descriptions.
