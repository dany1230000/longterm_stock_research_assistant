# 00631L v5.9 Settings Account Summary

Release tag: `00631l-lab-v5.9-settings-account-summary`

## Scope

v5.9 makes the settings page easier to use on mobile by putting account,
local data, selected ETF, frontend mode, and daily readiness at the top.

## Changes

- Added a compact `設定總覽` card group.
- The first settings screen now shows:
  - account state: no login required
  - selected ETF and price-history source
  - frontend data mode and backend connection state
  - daily readiness and latest report status
- Existing app store, data coverage, and maintenance diagnostics remain
  available in expandable sections.

## Data Behavior

- No parser or data-source behavior changed.
- No TX live behavior changed.
- No external account or brokerage login was added.
- Position data remains local-only.

## Validation

- Widget coverage verifies the new settings overview is visible.
- Backend health metadata is updated to v5.9.
- Release check requires this summary file.
