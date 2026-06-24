# 00631L lab v5.37 public Pages checkup

## Scope

v5.37 adds one concise public Pages checkup command for daily phone-readiness
verification. It combines the public PWA smoke check and the GitHub Pages
deployment-status check into a single result.

## Changes

- Added `scripts\00631l_public_pages_checkup.cmd`.
- Added `backend/scripts/public_pages_checkup_00631l.py`.
- Added release-check coverage for the checkup command.
- Added backend tests for pass, workflow-waiting, and public-smoke failure
  outcomes.
- Updated backend release metadata to `00631l-lab-v5.37-public-pages-checkup`.

## Usage

Run:

```cmd
scripts\00631l_public_pages_checkup.cmd
```

The result prints:

- public root URL
- static public data row count
- coverage range
- latest Pages workflow status
- latest Pages workflow conclusion
- action items when the public page is still deploying or static data is not
  usable

## Validation

Run:

```cmd
scripts\00631l_public_pages_checkup.cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```
