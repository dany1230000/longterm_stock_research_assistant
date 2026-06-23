# 00631L lab v4.75 public batch regression guidance

v4.75 improves action items when a public ETF catalog batch observes
`readyCount` moving backward during the same run.

## What changed

- The batch runner now includes `readyCountRegression` in the summary.
- If final `readyCount` is lower than the initial value, the action item
  prioritizes checking the public backend persistent data volume and redeploy
  status.
- In that condition, the runner no longer suggests retrying the failed offset
  first.

## Why

A ready-count decrease during one run usually points to public deployment or
storage instability, not a normal catalog offset problem. Continuing offsets
can hide the actual persistence issue.

## Verification

- `py -m unittest backend.tests.test_public_catalog_batch_runner`
- Full release validation remains covered by `scripts\00631l_release_check.cmd`.

This is maintenance guidance only. It does not add trading signals, forecasts,
notifications, or TX live expansion.
