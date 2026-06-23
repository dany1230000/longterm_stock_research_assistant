# 00631L lab v4.92 public fresh marker batch gate

Release goal: prevent public ETF catalog batches from running while the public backend looks newly recreated.

## What changed

- `scripts\00631l_public_maintenance_status.cmd` now marks the public persistence marker as fresh when:
  - `persistenceMarkerNewlyCreated` is true, or
  - marker age is under 15 minutes, and
  - public ETF history `readyCount` is still below the configured floor.
- When the marker is fresh, maintenance status hides ETF catalog batch commands.
- The summary now includes:
  - `publicPersistenceMarkerFresh`
  - `publicPersistenceMarkerFreshThresholdSeconds`

## Why it matters

A hosted backend can report `/ready` as writable even when its data directory is only an ephemeral filesystem. If a deploy recreates the marker and ETF history `readyCount` drops, running more catalog batches can waste time and produce misleading progress.

## Operating rule

If public maintenance shows a fresh marker and low ETF ready count:

1. Do not continue public ETF catalog batches.
2. Verify that the hosting platform has a persistent volume mounted at the configured data path.
3. Redeploy and confirm the marker `createdAt` stays stable across deploys.
4. Continue only with small one-item catalog batches after readiness, marker stability, and readyCount are healthy.
