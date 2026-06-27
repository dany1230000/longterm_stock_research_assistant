# 00631L lab v5.97 Pages missing ETF probe

v5.97 connects the missing ETF reason probe to the public Pages static build.

## What Changed

- `.github\workflows\deploy_web.yml` now runs a small missing ETF probe before
  static export on every Pages build.
- The probe uses the existing TWSE STOCK_DAY importer with:
  - `--from-catalog`
  - `--missing-only`
  - `--limit 20`
  - `--start-date 2026-06-01`
  - `--allow-partial`
- The step is `continue-on-error`, so a temporary official-source issue does not
  block the 00631L public app from publishing existing static data.
- `scripts\00631l_build_pages_static.cmd --probe-missing` gives the same
  behavior locally when explicitly requested.

## Expected Result

Public static data can gradually move ETF gaps away from plain `not_saved`:

- official rows found -> ETF history becomes ready in the deployed static JSON.
- official empty response -> gap can be classified as `official_empty`.
- source or validation issues -> gap can be classified separately.

The generated data remains deployment output. It is not committed to git.
