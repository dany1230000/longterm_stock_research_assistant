# 00631L lab v5.41 public release mismatch guidance

## Scope

v5.41 makes public Pages checkup more explicit when the public static bundle is
valid but still points to an older commit.

## Changes

- Public Pages checkup summary now includes `releaseMatchesExpected`.
- If `release.json` exists but its commit SHA does not match `--expected-sha`,
  the checkup reports WARN with failures empty.
- The action item now explains that public Pages is still serving a previous
  release and should be checked again after deployment finishes.

## Daily Check

Run:

```cmd
scripts\00631l_public_pages_checkup.cmd --skip-github-api --expected-sha <commit>
```

Interpretation:

- `releaseMarkerStatus=ready` and `releaseMatchesExpected=true`: public static
  bundle matches the expected release.
- `releaseMarkerStatus=ready` and `releaseMatchesExpected=false`: public static
  bundle is reachable but still older than the expected release.
- `failureCount=0`: the public app remains reachable; this is a deployment
  timing warning, not a data corruption signal.

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
