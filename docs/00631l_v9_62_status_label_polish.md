# 00631L lab v9.62 status label polish

v9.62 makes the first mobile screen read more like a product UI and less like a
debug panel.

## Changes

- The quote-card status display now uses short Chinese labels for mock/default
  and live-proxy states.
- The phone-width overview test guards against showing raw `Mock` text on the
  first screen.
- Data-source behavior is unchanged: mock/default data is still labeled as a
  fallback state and is not presented as official data.

## Validation scope

- Widget coverage verifies the phone-width overview stays readable and uses the
  localized fallback label.
- No parser, repository, backend, or source-priority behavior changed.
