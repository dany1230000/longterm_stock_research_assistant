# 00631L lab v9.54 - deploy warning classification

Date: 2026-06-30

## Goal

Keep post-deploy validation wording accurate when public data is aligned but the
backend still reports a non-data warning.

## Change

- `scripts\00631l_wait_public_deploy.cmd` now separates:
  - data freshness gaps, such as stale coverage or missing ETF histories
  - non-data backend warnings, such as a fresh persistence marker after deploy
- When coverage, catalog rows, and ETF history readiness are aligned, deploy
  wait no longer labels the warning as a data freshness problem.

## Why

After a deploy, the backend can briefly report a persistence-marker warning even
when 00631L history and ETF catalog data are fully aligned. The script should
not suggest data maintenance unless there is an actual data gap.

## Scope

This release changes deploy validation wording and classification only. It does
not alter data ingestion, ETF scope, TX live sourcing, notifications, automated
actions, or investment guidance.
