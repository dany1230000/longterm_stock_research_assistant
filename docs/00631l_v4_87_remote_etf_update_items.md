# 00631L v4.87 Remote ETF Update Items

Status: shipped

## Scope

v4.87 improves maintenance payload detail for public ETF history updates. It
does not change ETF scope, holdings parsing, TX live behavior, or user-facing
analysis wording.

## Changes

- Remote ETF history update wrappers now preserve `requestedCodes`.
- Remote update payloads include `updatedCount`.
- Per-code update `items` are passed through so downstream batch output can show
  `savedRows`, row count, coverage range, source status, and error details.
- Tests cover wrapper output for catalog batch requests.

## Operational Rule

Use the per-code item details to verify whether a catalog batch actually saved
history rows. A ready-count increase is still the primary public readiness
signal.
