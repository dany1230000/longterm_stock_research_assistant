# 00631L v4.54 Backend Release Metadata

## Scope

v4.54 makes backend version and deployment metadata explicit in health and operations payloads.

## What Changed

- `/health` no longer hard-codes the old `3.4-live-backend` value.
- Backend release metadata can be configured with:
  - `00631L_BACKEND_APP_VERSION`
  - `00631L_BACKEND_RELEASE_TAG`
  - `00631L_BACKEND_GIT_SHA`
  - `00631L_BACKEND_BUILD_TIME`
- `/health` now returns:
  - `appVersion`
  - `release.version`
  - `release.tag`
  - `release.gitSha`
  - `release.buildTime`
- `/api/etf/00631l/operations/status` includes `config.backendRelease`.
- The Flutter operations model maps backend release metadata.
- Settings/system status shows a compact `backend release` row.

## Why It Matters

When the public backend is deployed separately from GitHub Pages, the phone app must show which backend release it is connected to. This avoids confusing stale deployments with current data issues.

## Deployment Notes

For Render or Docker deployments, set:

```env
00631L_BACKEND_APP_VERSION=4.54-release-metadata
00631L_BACKEND_RELEASE_TAG=00631l-lab-v4.54-release-metadata
00631L_BACKEND_GIT_SHA=<commit-sha>
00631L_BACKEND_BUILD_TIME=<build-time-iso8601>
```

Leaving `gitSha` or `buildTime` blank is allowed, but the app will show less precise traceability.
