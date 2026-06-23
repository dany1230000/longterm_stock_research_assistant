# 00631L v4.86 Public Readiness Probe

Status: shipped

## Scope

v4.86 hardens public maintenance before running ETF catalog history batches.
It does not change analysis wording, TX live behavior, or ETF scope.

## Changes

- `scripts\00631l_public_maintenance_status.cmd` now performs an independent
  `/ready` probe in addition to the full public status check.
- If any readiness sample is WARN/FAIL, catalog batch commands are removed from
  action items.
- Readiness and persistence action items remain visible so the next program
  step is clear.
- Tests cover the case where one public status sample misses a readiness
  failure but the independent probe catches it.

## Operational Rule

Do not run public ETF catalog batches while the public backend readiness probe
is WARN/FAIL. Fix the public backend data directory or persistent volume first,
then rerun public status checks.
