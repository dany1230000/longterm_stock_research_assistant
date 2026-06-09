# 00631L lab v1.44 release summary

Completed on 2026-06-09.

## Scope

v1.44 makes the latest local daily report easier to read from `/00631l-lab`.

## Changes

- The daily data status section now includes a `latest daily report` panel.
- When a report exists, the panel shows:
  - report overall status
  - generated time
  - WARN count
  - FAIL count
  - local report path
- When no report exists, the panel shows a missing state and the manual report generation command.
- Widget coverage verifies that report metadata is visible without adding any investment guidance.

## Behavior

- The backend report metadata contract is unchanged.
- The report remains local operational state under ignored `backend/reports/`.
- The app still falls back safely when backend or local report state is unavailable.

## Limits

- No TX live source was added.
- No notifications were added.
- No investment guidance was added.

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
