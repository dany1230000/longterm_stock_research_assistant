# 00631L v4.88 Public Regression Batch Gate

Status: shipped

## Scope

v4.88 hardens public ETF catalog maintenance. It does not add investment
analysis, TX live changes, notifications, or broader trading features.

## Changes

- Public maintenance status now treats public ETF ready-count regression as a
  batch blocker.
- Upstream batch action items from freshness checks are filtered when regression
  is detected.
- The visible action item tells the operator to fix public backend persistence
  before continuing catalog batches.
- Tests cover regression plus upstream batch suggestions.

## Operational Rule

If public readyCount is lower than the last successful batch state, do not run
more catalog batches. Confirm the public backend persistent data volume first.
