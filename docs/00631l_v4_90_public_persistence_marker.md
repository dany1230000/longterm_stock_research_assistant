# 00631L lab v4.90 public persistence marker

Release goal: prove whether the public backend keeps the same data volume across redeploys.

## What changed

- Added `00631L_PERSISTENCE_MARKER_PATH`.
- `/ready` now includes a `persistence_marker` check.
- `/ready` also returns `persistenceMarker` metadata:
  - `createdAt`
  - `lastCheckedAt`
  - `markerAgeSeconds`
  - `newlyCreated`
  - `path`
- `operations/status` exposes the same marker under `dataDirectoryHealth.persistenceMarker`.
- `scripts\00631l_public_backend_status.cmd` summarizes marker age and whether it was newly created.

## How to read it

If `newlyCreated=true` immediately after a redeploy, the backend may be seeing a fresh data directory. If the marker keeps the same `createdAt` across redeploys, the mounted data volume is more likely to be stable.

Use this together with ETF history `readyCount`. If `readyCount` drops after a deploy and the marker is new, fix the public backend persistent volume before running more ETF catalog batches.

## Expected public env

```text
00631L_DATA_DIR=/data/00631l
00631L_DATA_PERSISTENCE_MODE=persistent
00631L_PERSISTENCE_MARKER_PATH=/data/00631l/00631l_persistence_marker.json
```
