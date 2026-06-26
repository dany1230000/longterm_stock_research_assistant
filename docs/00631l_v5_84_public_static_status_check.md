# v5.84 Public Static Status Check

## Scope

v5.84 adds a read-only checker for the GitHub Pages static data bundle:

```cmd
scripts\00631l_check_public_static_data.cmd
```

The checker reads these public files from GitHub Pages:

- `00631l-static-data/status.json`
- `00631l-static-data/manifest.json`
- `00631l-static-data/release.json`

It merges the fields that are intentionally split across those files, including:

- 00631L price-history row count and coverage range
- static source status
- ETF catalog row count
- ETF price-history ready and missing counts
- ETF coverage-tier counts
- public release tag, app version, and git SHA

## Why

`status.json` focuses on the 00631L price-history payload. ETF catalog readiness is
stored in `manifest.json`. Checking only one file can make public static data look
incomplete even when the deployed bundle is healthy.

This checker gives one compact PASS/WARN/FAIL summary for daily verification and
release validation.

## Expected Usage

```cmd
scripts\00631l_check_public_static_data.cmd
scripts\00631l_release_check.cmd
```

`release_check` now runs the public static data checker automatically.

## Status Semantics

- `PASS`: public static data is reachable and has expected metadata.
- `WARN`: data is reachable, but one non-critical marker is missing or below an
  expected floor.
- `FAIL`: `status.json` or `manifest.json` cannot be fetched or parsed.

Static public data supports public history and backtest usage. Live intraday NAV
still requires the public backend.
