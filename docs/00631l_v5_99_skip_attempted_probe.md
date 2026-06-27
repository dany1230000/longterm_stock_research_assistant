# 00631L lab v5.99 skip attempted ETF probe

v5.99 makes the public missing-ETF probe advance through the catalog instead of
checking the same already-attempted symbols on every GitHub Pages deployment.

## What Changed

- `backend\scripts\import_etf_price_history.py` adds `--skip-attempted`.
- The flag applies only with `--missing-only`.
- Existing import-attempt evidence is respected before the batch limit is
  applied.
- `scripts\00631l_probe_missing_etf_reasons.cmd` now uses `--skip-attempted`.
- `.github\workflows\deploy_web.yml` uses the same flag in the public Pages
  probe step.

## Why

The public static build probes a small batch of missing ETF histories before it
exports static data. Without skipping already-attempted symbols, the workflow
can keep checking the first missing batch and leave later gaps as `not_saved`.

Skipping attempted symbols lets later deployments move to the next missing
batch. This improves gap classification without inventing historical data and
without blocking the 00631L public app when an official source has no rows for a
symbol.

## Verification

Use these commands for the local maintenance path:

```cmd
scripts\00631l_probe_missing_etf_reasons.cmd --status-only
scripts\00631l_release_check.cmd
```

Generated import-attempt files remain local ignored state. They are evidence for
maintenance status, not committed source data.
