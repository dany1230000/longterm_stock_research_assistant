# 00631L lab v1.47 release summary

Completed on 2026-06-09.

## Scope

v1.47 strengthens release validation with deployment precheck coverage.

## Changes

- Added `backend/scripts/deploy_precheck_00631l.py`.
- Added `scripts/00631l_deploy_precheck.cmd`.
- `scripts\00631l_release_check.cmd` now runs:
  - deployment precheck
  - retention policy dry-run
  - the previous Flutter, backend, daily cycle, export, report, integrity, backup, restore, smoke, wording, and diff checks
- Required maintenance artifact checks now include the deployment precheck and retention policy files.
- Backend tests cover deploy precheck failure and minimal local layout acceptance.

## Deploy Precheck Coverage

- Flutter clean SDK path presence.
- backend `.env.example` and optional local `.env`.
- web metadata files.
- daily-use scripts.
- daily-use docs.
- local data/export/backup/report directory readiness.

## Limits

- No TX live source was added.
- No notifications were added.
- No investment guidance was added.

## Validation

Run:

```cmd
scripts\00631l_deploy_precheck.cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```
