# 00631L lab v6.71 settings first-screen cleanup

v6.71 makes the account/settings tab read like a user-facing page instead of a
maintenance console on the first screen.

## What changed

- The top settings strip now shows local-only context, the current ETF, and the
  frontend data mode.
- Backend persistence and detailed data diagnostics remain available in the
  advanced status panels.
- The daily status tile now points to advanced diagnostics instead of surfacing
  raw maintenance labels on the first screen.
- Widget coverage verifies that technical diagnostics do not appear on the
  first phone-width settings screen.

## Scope

This is a UI information-architecture change only. It does not change:

- backend status calculations,
- persistent-data checks,
- public/static/live source labels,
- ETF history eligibility,
- position storage or calculations,
- AI analysis output.
