# 00631L lab v4.93 release metadata refresh

Release goal: keep public backend release metadata aligned with the current deployment target.

## What changed

- Backend default release metadata now reports:
  - app version `4.93-release-metadata-refresh`
  - release tag `00631l-lab-v4.93-release-metadata-refresh`
- `/health` tests assert the current metadata.

## Why it matters

Public deploy wait and deploy drift checks compare the backend `/health` release tag against local release metadata. If the default metadata is stale, the helper can report the old deployment as current and skip the real wait.

## Operating rule

After each backend release:

1. Check `/health` release metadata.
2. Run `scripts\00631l_wait_public_deploy.cmd --soft-fail`.
3. Continue public maintenance only after deploy drift checks the intended tag.
