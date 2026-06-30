# 00631L lab v9.41 fast static race

Release goal: reduce the remaining public first-screen delay in live proxy
builds.

## Changes

- `Cached00631LRepository` now supports `raceFastFallback`.
- Public live builds with static data enabled use the race mode for
  `fetchFastLabData()`.
- When the live backend is slow or warming up, static preview data can render
  the first screen before the live proxy timeout.
- Full data loading still prefers the live backend and keeps static data as a
  truthful fallback.

## Verification

- Repository test covers a never-returning live fast path and verifies static
  preview returns within the fast startup budget.
