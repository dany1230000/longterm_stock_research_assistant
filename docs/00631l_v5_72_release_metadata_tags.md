# 00631L v5.72 Release Metadata Tags

Date: 2026-06-24

## Scope

v5.72 fixes public static release metadata so GitHub Pages can show the release
tag that matches the deployed commit.

## Changes

- Backend default release metadata is updated to `5.72-release-metadata-tags`.
- Static export can derive `appVersion` from an exact `00631l-lab-v*` tag on
  `HEAD`.
- GitHub Pages workflow now checks out full git history with tags by using
  `fetch-depth: 0`.

## Release Practice

For future releases, create the annotated tag locally before pushing. Prefer
pushing the tag first, then pushing `main`, so the Pages workflow can see the
tag when the branch build starts:

```cmd
git tag -a 00631l-lab-vX.Y-name -m "00631L lab vX.Y name"
git push origin 00631l-lab-vX.Y-name
git push origin main
```

The public release marker should then show:

- `releaseGitSha`: the deployed commit SHA
- `releaseTag`: the matching annotated release tag
- `appVersion`: the tag suffix after `00631l-lab-v`

## Validation

Run:

```cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
scripts\00631l_public_pages_checkup.cmd --skip-github-api --summary-only --expected-sha <HEAD>
git diff --check
```
