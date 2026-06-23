# 00631L lab v4.96 public persistence verifier

v4.96 adds a read-only verifier for the public backend persistent data volume.

## What changed

- Added `scripts\00631l_verify_public_persistence.cmd`.
- Added `backend\scripts\verify_public_persistence_00631l.py`.
- Release check now includes a dry-run of the verifier.
- The verifier samples public backend status and checks:
  - persistence marker exists
  - marker `createdAt` is stable between samples
  - marker is not fresh
  - marker age is above the verification window
  - public ETF ready count is above the configured floor
  - ready count does not regress between samples

## How to run

```cmd
scripts\00631l_verify_public_persistence.cmd --soft-fail
```

For a faster manual check:

```cmd
scripts\00631l_verify_public_persistence.cmd --sample-count 2 --interval-seconds 10 --soft-fail
```

## Interpretation

- `PASS`: public data persistence looks stable enough to continue public ETF data maintenance.
- `WARN`: review action items before running catalog batches.
- `FAIL`: backend connectivity or status sampling failed.

Do not continue public ETF catalog batches while the verifier reports a fresh
marker, changed marker `createdAt`, or ready-count regression.

## Scope

This is an operations guard. It does not change ETF analysis logic and does not
add any investment guidance.
