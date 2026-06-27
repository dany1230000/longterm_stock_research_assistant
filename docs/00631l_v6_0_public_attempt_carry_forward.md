# 00631L lab v6.0 public ETF attempt carry-forward

v6.0 lets GitHub Pages deployments reuse public ETF import-attempt evidence from
the previous static export before running the next missing-ETF probe.

## What Changed

- Added `backend\scripts\restore_public_etf_attempts.py`.
- Added `scripts\00631l_restore_public_etf_attempts.cmd`.
- GitHub Pages now restores public attempt evidence before missing-only ETF
  imports.
- Missing-only ETF batches now use `--skip-attempted`.
- Local Pages build can opt in with:

```cmd
scripts\00631l_build_pages_static.cmd --restore-public-attempts --probe-missing
```

## Why

GitHub Actions runners start clean. The previous `_attempts` directory is not
available unless it is restored from a public artifact. After v5.99, the public
build could still report the same 20 attempted ETFs because the runner had no
memory of the last deployment.

The static public `etf_price_history_index.json` already contains
`lastImportAttempt` evidence for missing ETFs. v6.0 reads that public index,
restores the evidence into the runner's local ETF history store, and then runs
the missing-only probe. Later deployments can then move to later missing
symbols.

## Data Boundary

This does not invent missing ETF histories. It only carries forward evidence
that a public static export already reported. Price rows still come from the
official TWSE STOCK_DAY source or committed official seed files.

If the public index is temporarily unavailable, the restore command returns
WARN with no failures so the Pages build can still export the existing static
00631L data.
