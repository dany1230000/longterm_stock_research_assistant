# 00631L lab v4.77 deploy drift git SHA noise

v4.77 reduces false WARN output in the public backend deploy drift check.

## What Changed

- `scripts\00631l_public_deploy_drift.cmd` still compares the public backend
  release tag against the local expected release tag.
- If the public release tag matches, a missing public git SHA no longer changes
  the overall result to WARN.
- The response still exposes `publicGitShaStatus: missing` so deployment
  metadata quality stays visible.
- If the release tag differs, or both git SHAs are present but different, the
  check still reports WARN.

## Why

Some hosted deployments expose the release tag but do not inject
`00631L_BACKEND_GIT_SHA`. When the tag already proves the backend release is
current, warning on the missing SHA creates noise in daily public maintenance
status.

## Validation

```cmd
py -m unittest backend.tests.test_public_backend_deploy_drift
scripts\00631l_public_deploy_drift.cmd --soft-fail
scripts\00631l_release_check.cmd
```

This change only affects deployment metadata reporting. It does not change
official data parsing, ETF history import, static-public fallback, or intraday
source labeling.
