# 00631L lab v5.40 public release guidance

## Scope

v5.40 makes public Pages checkup output easier to act on while GitHub Pages is
still deploying a new release.

## Changes

- Public Pages checkup summary now includes:
  - `releaseMarkerStatus`
  - `releaseTag`
  - `releaseGitSha`
  - `releaseAppVersion`
- If `release.json` is missing or not checked yet, the checkup keeps failures
  empty but adds a program action:

```cmd
scripts\00631l_public_pages_checkup.cmd --skip-github-api
```

- This keeps daily phone-app checks useful even when GitHub workflow API access
  is rate-limited.

## Expected Deploy Lag

Right after pushing a release, public Pages may still serve the previous static
bundle. In that window, the app can still be reachable and data can still be
usable, while `releaseMarkerStatus` is not `ready`.

Rerun the checkup after Pages finishes:

```cmd
scripts\00631l_public_pages_checkup.cmd --skip-github-api --expected-sha <commit>
```

## Validation

Run:

```cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```
