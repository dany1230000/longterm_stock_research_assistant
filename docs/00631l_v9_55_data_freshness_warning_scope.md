# 00631L lab v9.55 - data freshness warning scope

Date: 2026-06-30

## Goal

Keep the public data freshness check focused on actual data gaps.

## Change

- `scripts\00631l_compare_public_freshness.cmd` no longer returns WARN only
  because the public backend status has a non-data warning.
- The script still fails when the public backend status fails.
- The script still warns when public data is stale, row counts are too low, ETF
  history readiness lags static data, or catalog/history gaps exist.
- The public backend overall status is preserved in the freshness summary for
  context.

## Why

The public backend may briefly report a persistence-marker warning after deploy
while 00631L history, static data, catalog rows, and ETF histories are fully
aligned. Data freshness checks should not imply a data problem in that case.

## Scope

This release only changes maintenance-check classification. It does not change
data ingestion, UI behavior, ETF scope, TX live sourcing, notifications,
automated actions, or investment guidance.
