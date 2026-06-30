# 00631L lab v9.46 - brief Pages wait output

Date: 2026-06-30

## Goal

Keep post-push deployment verification readable during daily maintenance.

## Change

`scripts\00631l_wait_pages_deploy.cmd` now supports:

```cmd
scripts\00631l_wait_pages_deploy.cmd --expected-sha <commit-sha> --summary-only
scripts\00631l_wait_pages_deploy.cmd --expected-sha <commit-sha> --include-attempts
```

`--summary-only` removes the full sampled payloads and keeps a compact attempt
summary.

`--include-attempts` keeps compact per-attempt rows and can be used without
`--summary-only`.

## Why

The marker-first wait can collect many samples while GitHub Pages deploys. Daily
checks should show the release tag, git SHA, static row count, and coverage
without dumping every public smoke payload.
