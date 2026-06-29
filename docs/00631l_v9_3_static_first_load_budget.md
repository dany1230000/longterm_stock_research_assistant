# 00631L v9.3 Static First-Load Budget

Date: 2026-06-29

## Goal

Keep the public mobile first screen from regressing into loading the full ETF
catalog and ETF price-history index before the user opens search or comparison.

## What Changed

- Added `scripts\00631l_check_static_first_load_budget.cmd`.
- The script runs the focused repository regression test that records static
  requests and fails if first-screen lab data reads:
  - `etf_catalog.json`
  - `etf_price_history_index.json`
- Release check now runs this guard before the full Flutter test suite.

## Result

The static-public app keeps a small first-screen request set while preserving
on-demand ETF search and comparison data.
