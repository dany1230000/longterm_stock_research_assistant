# 00631L lab v4.84 public batch test state isolation

v4.84 prevents backend tests from polluting local public catalog batch state.

## What changed

- `run_public_etf_catalog_batches()` now writes the default resume state only
  for real CLI-style runs.
- Tests and fixture-driven calls that inject a requester, maintenance runner,
  preflight checker, or catalog row count do not write
  `backend\data\00631l_public_etf_catalog_batch_state.json` unless they pass an
  explicit `state_path`.
- Existing explicit state-path tests still verify resume-state persistence.

## Why

Release checks run backend tests. Before v4.84, a test using
`https://example.com` could overwrite the ignored local batch state and make
public maintenance guidance point at a fake failed offset. This release keeps
operational state separate from unit-test state.
