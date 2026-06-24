# 00631L lab v5.38 public checkup rate-limit hardening

## Scope

v5.38 makes the public Pages daily check less dependent on the GitHub API. The
public phone app and static data can now be checked without querying workflow
metadata, which avoids noisy WARN results when unauthenticated GitHub API quota
is temporarily exhausted.

## Changes

- `scripts\00631l_public_pages_checkup.cmd` now supports:

```cmd
scripts\00631l_public_pages_checkup.cmd --skip-github-api
```

- `--public-only` is an alias for the same mode.
- Release check uses the public-only checkup mode after the separate Pages
  deploy-status step, so workflow API metadata is queried once instead of twice.
- When GitHub API rate limiting is detected, the checkup action item points to
  the public-only command.
- Backend metadata is updated to
  `00631l-lab-v5.38-public-checkup-rate-limit`.

## Daily Use

Use this when the goal is only to verify the public PWA and static data:

```cmd
scripts\00631l_public_pages_checkup.cmd --skip-github-api
```

Use this after a push when workflow status also matters:

```cmd
scripts\00631l_wait_pages_deploy.cmd
```

## Validation

Run:

```cmd
scripts\00631l_public_pages_checkup.cmd --skip-github-api
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```
