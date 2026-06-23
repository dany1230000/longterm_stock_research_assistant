# 00631L lab v4.91 public marker maintenance summary

Release goal: show persistence marker evidence directly in public maintenance status.

## What changed

- `scripts\00631l_public_maintenance_status.cmd` now includes:
  - `publicPersistenceMarkerCreatedAt`
  - `publicPersistenceMarkerAgeSeconds`
  - `publicPersistenceMarkerNewlyCreated`
- If the public marker is newly created, maintenance status adds a warning and an action item to recheck after the next deploy.

## Why it matters

ETF history `readyCount` can drop if a public backend deploy sees a fresh data directory. The marker gives a second signal: if `createdAt` changes after each deploy, persistent storage is not stable enough for long public catalog batches.

## Operating rule

Before running long public ETF catalog batches:

1. Confirm deploy drift is PASS.
2. Confirm readiness is PASS.
3. Confirm marker `createdAt` stays stable across at least one deploy.
4. Confirm readyCount does not regress.

If these checks are healthy, continue with small batches first.
