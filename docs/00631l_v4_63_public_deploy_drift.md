# 00631L v4.63 Public Deploy Drift Check

Release goal: make it obvious when the public backend is still running an older release than the local main branch.

## What Changed

- Added `backend/scripts/check_public_deploy_drift_00631l.py`.
- Added `scripts\00631l_public_deploy_drift.cmd`.
- Updated backend default release metadata to:
  - `00631L_BACKEND_APP_VERSION=4.63-public-deploy-drift`
  - `00631L_BACKEND_RELEASE_TAG=00631l-lab-v4.63-public-deploy-drift`
- Release check now includes the deploy drift checker in dry-run mode.

## Usage

```cmd
scripts\00631l_public_deploy_drift.cmd --soft-fail
```

If the public backend reports an older release tag, the script returns `WARN` and asks the operator to redeploy the public backend from latest `main`.

## Notes

This check does not mutate backend data. It reads `/health` and the public backend status summary, then compares the public release tag and git sha with the expected local release metadata.
