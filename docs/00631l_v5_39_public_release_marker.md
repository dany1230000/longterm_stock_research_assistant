# 00631L lab v5.39 public release marker

## Scope

v5.39 adds a public release marker to the static Pages data bundle. This lets
daily checks read the deployed app version, release tag, commit SHA, and build
time directly from GitHub Pages static files.

## Changes

- Static export now writes `web\00631l-static-data\release.json`.
- Static `manifest.json` includes the same release metadata and points to the
  release marker file.
- Public Pages smoke checks `release.json` and reports:
  - app version
  - release tag
  - git SHA
  - build time
- If the public release SHA differs from the expected local SHA, the check
  reports WARN instead of FAIL. This is expected while GitHub Pages is still
  deploying.

## Why This Matters

GitHub API workflow checks can be rate-limited. The release marker is served by
the public PWA itself, so the app can still be checked from the same path a
phone uses:

```cmd
scripts\00631l_public_pages_checkup.cmd --skip-github-api
```

## Validation

Run:

```cmd
scripts\00631l_export_static_data.cmd --update
scripts\00631l_check_public_pages.cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```
