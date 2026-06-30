# 00631L lab v9.53 - post-deploy freshness wait

Date: 2026-06-30

## Goal

Make public deploy validation check both release metadata and data freshness.

## Change

- `scripts\00631l_wait_public_deploy.cmd` still waits for the expected public
  backend release tag.
- After the release tag is observed, it now also runs the public/local/static
  freshness comparison.
- The wait output summarizes:
  - public 00631L coverage end
  - local and static coverage end
  - public/static ETF catalog row counts
  - public/static ETF history ready counts
  - public catalog/history gap count
- If the deploy is current but data is stale, the script returns WARN with
  program actions such as running remote maintenance or ETF catalog batches.
- `--skip-freshness` is available for release-metadata-only checks.

## Why

A public backend deploy can expose the new release tag before persistent data has
been refreshed. Waiting only for the tag can hide stale 00631L history or ETF
catalog gaps. This check makes post-deploy data refresh needs visible.

## Scope

This release changes deployment validation only. It does not change the app UI,
ETF selection logic, TX live sourcing, notifications, automated actions, or
investment guidance.
