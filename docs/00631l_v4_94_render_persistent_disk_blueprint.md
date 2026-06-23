# 00631L lab v4.94 Render persistent disk blueprint

Release goal: make the Render deployment template explicitly mount persistent storage for public backend data.

## What changed

- Added root `render.yaml` for Render Blueprint deployments.
- Added `disk` configuration to both:
  - `render.yaml`
  - `deploy\render.yaml`
- The disk mounts at `/data/00631l`, matching `00631L_DATA_DIR`.
- Public config checks now verify Render disk fields:
  - `disk`
  - `mountPath: /data/00631l`
  - `sizeGB`

## Why it matters

The public backend can pass writable checks while still using an ephemeral filesystem. A persistent disk mounted at the same path used by the backend data directory is required for ETF history, reports, exports, backups, and persistence marker stability across deploys.

## Operating rule

For Render:

1. Deploy using the root `render.yaml` Blueprint, or manually add a persistent disk in the Render dashboard.
2. Mount the disk at `/data/00631l`.
3. Set `00631L_DATA_DIR=/data/00631l`.
4. Set `00631L_DATA_PERSISTENCE_MODE=persistent`.
5. Confirm `publicPersistenceMarkerCreatedAt` stays stable after the next deploy.
