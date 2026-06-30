# 00631L lab v9.56 - public post-deploy refresh

## Goal

Render redeploy can briefly expose seed/static backend data before the public
persistent store is refreshed. v9.56 adds one operational command that waits for
the expected backend release, runs daily maintenance, fills public ETF catalog
history gaps, and then compares public/local/static freshness again.

## New command

```cmd
scripts\00631l_public_post_deploy_refresh.cmd --base-url https://longterm-stock-research-assistant.onrender.com --expected-release-tag 00631l-lab-v9.56-public-post-deploy-refresh --soft-fail
```

Dry-run mode is included in the release check:

```cmd
scripts\00631l_public_post_deploy_refresh.cmd --dry-run
```

## What it checks

1. Waits for the public backend release marker.
2. Runs remote daily maintenance.
3. Reads `/api/etf/catalog`.
4. Reads `/api/etf/history/gaps?fromCatalog=true`.
5. Converts each gap code to the catalog offset and runs a one-symbol batch.
6. Runs public data freshness comparison.

The script prints `overallStatus`, warnings, failures, gap count, batch count,
and final freshness status. It does not store secrets and does not commit local
backend data.

## GitHub Actions

The public backend maintenance workflow now runs post-deploy refresh for `daily`
and `all` modes with `--soft-fail`. A transient TWSE/Render/network WARN should
be reviewed, but it should not hide test/build failures elsewhere.

## Status rules

- `PASS`: release marker, maintenance, gap refresh, and freshness all pass.
- `WARN`: public data may need another maintenance pass, or a remote endpoint was
  temporarily unavailable.
- `FAIL`: a hard failure was reported by a required step.

This remains an operational data-health check only. It is not an investment
recommendation.
