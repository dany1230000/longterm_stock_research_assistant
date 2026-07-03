# 00631L v15.14 position empty first screen

## Scope

This release tightens the phone position tab when no local position has been
entered yet.

## Changes

- Phone-width empty position state now starts directly with the local input
  card.
- The empty account summary is hidden until position data exists, avoiding
  repeated placeholder metrics before the user enters shares and average cost.
- Desktop and saved-position layouts keep the position summary behavior.

## Non-goals

- No change to position calculations.
- No account login or external sync.
- No trading guidance.
