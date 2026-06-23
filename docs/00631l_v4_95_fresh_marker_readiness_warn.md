# 00631L lab v4.95 fresh marker readiness warning

Release goal: make backend readiness expose newly recreated persistent data directories earlier.

## What changed

- Persistence marker payload now includes:
  - `fresh`
  - `freshThresholdSeconds`
- `/ready` marks `persistence_marker` as `WARN` when:
  - backend is configured as `00631L_DATA_PERSISTENCE_MODE=persistent`, and
  - the marker is newly created or younger than 15 minutes.
- Public backend status carries the fresh marker fields into summaries.

## Why it matters

A backend can write to `/data/00631l` even when that path is not actually persisted across deploys. A fresh marker after deploy is a practical early signal that the service may be using a newly created data directory.

## Operating rule

When `/ready` shows a fresh persistence marker:

1. Treat it as deployment review, not app failure.
2. Confirm the marker `createdAt` remains stable after another deploy or restart.
3. Do not continue public ETF catalog batches while the marker is fresh and public ETF history ready count is below target.
