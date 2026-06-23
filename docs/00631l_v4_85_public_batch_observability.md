# 00631L v4.85 Public Batch Observability

Status: shipped

## Scope

v4.85 improves the public ETF catalog batch runner output. It does not change
ETF scope, TX live behavior, or user-facing analysis rules.

## Changes

- Public catalog batch steps now include `requestedCodes`.
- Batch summaries include `sourceStatus`, `updatedCount`, `readyCount`, and
  per-item `savedRows`, `rowCount`, coverage, and `errorMessage`.
- A catalog row that returns no usable TWSE history remains a WARN and is not
  counted as ready.
- Tests cover single-batch item summaries and full batch step summaries.

## Operational Rule

If a batch reports `savedRows=0`, keep the result as unavailable/error for that
code and continue with the next offset only after public readiness and history
stability are acceptable.
