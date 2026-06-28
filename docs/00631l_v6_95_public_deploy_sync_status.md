# 00631L lab v6.95 public deploy sync status

v6.95 makes public frontend/backend version drift visible inside the app.

## What changed

- `EtfOperationsStatus` now derives a deployment sync state from static Pages
  release metadata and backend release metadata.
- The Settings/My first screen shows a short `synced`, `version drift`,
  `backend unknown`, or `static only` badge.
- The advanced maintenance panel includes `Deploy sync` with:
  - frontend/static release metadata
  - backend release metadata
  - a program action for redeploying or setting release metadata

## Why

The public GitHub Pages frontend can update before the public Render backend is
redeployed. The app should keep live/static fallback behavior truthful, but the
user also needs a concise status that explains why Pages and backend may not
show the same release version.

## Scope

- No data source changes.
- No TX live changes.
- No static history row changes.
- No investment guidance.
