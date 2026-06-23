# 00631L lab v4.98 public persistence fail classification

v4.98 refines `scripts\00631l_verify_public_persistence.cmd`.

## What changed

When the public backend returns a usable status payload but `/ready` reports
storage or persistence failures, the verifier now reports `WARN` instead of
marking the verifier itself as failed.

Network errors, missing status payloads, and request exceptions can still report
`FAIL`.

## Why it matters

The verifier is an operations gate. It should separate two cases:

- the checker could not observe the backend
- the backend was observed and reported a persistence problem

The second case is actionable deployment state and should keep public ETF data
batches blocked without making the checker look broken.
