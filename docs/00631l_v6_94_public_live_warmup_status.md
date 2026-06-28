# 00631L lab v6.94 - public live warmup status

## Goal

Make the GitHub Pages first screen clearer while the public Render backend is
waking up. The app should not make a temporary live-proxy cold start look like a
confirmed official-data error.

## Changes

- The overview DAY chip now shows `喚醒中 / 後端` when live proxy is enabled and
  the full live data request is still loading.
- Once the live backend returns data, the existing official/cached/stale/error
  labels are used as before.
- Non-live builds and completed error states still show unavailable/error
  labels, so mock/fallback data is not presented as official.
- Added widget-level coverage for the live-backend warmup display helper.

## Validation

- Targeted widget validation passed.
- Full validation: Flutter analyze/test/build, backend tests, release check
  with acceptable WARN-only output and `failures=0`, and `git diff --check`.
