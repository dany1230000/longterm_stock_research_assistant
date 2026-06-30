# 00631L lab v9.48 - public backend drift tag

Date: 2026-06-30

## Goal

Make public backend deploy-drift checks compare against the actual release tag
when the current commit has an `00631l-lab-v*` tag.

## Change

- Backend default release metadata now reports
  `00631l-lab-v9.48-public-backend-drift-tag`.
- `scripts\00631l_public_deploy_drift.cmd` resolves the expected release tag in
  this order:
  1. explicit `--expected-release-tag` or `EXPECTED_00631L_RELEASE_TAG`
  2. exact `00631l-lab-v*` tag on `HEAD`
  3. backend config default
- The drift check therefore catches a public backend that still exposes an older
  `/health` release tag after the frontend and Pages release have moved ahead.

## Why

The public Render backend can be deployed separately from GitHub Pages. A stale
backend release tag should be visible as a deployment drift warning, not hidden
by an old local default.

## Scope

This release changes release metadata and deploy-drift checks only. It does not
change live data sources, TX quote sourcing, ETF scope, portfolio storage,
notifications, or investment guidance.
