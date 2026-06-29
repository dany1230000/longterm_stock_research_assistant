# 00631L v9.1 Lazy Static Catalog

Date: 2026-06-29

## Goal

Keep the public static first screen focused on the core quote/history data and
defer the full ETF catalog plus ETF price-history index until the user opens ETF
search, comparison, or detail workflows.

## What Changed

- Static fast/full lab data no longer reads `etf_catalog.json` or
  `etf_price_history_index.json`.
- Static operations status still exposes compact ETF library readiness from
  `status.json`.
- The left-top ETF search sheet now watches the catalog provider directly, so
  the full catalog loads only when the search sheet opens.
- Cached fallback no longer fills a static-public first screen with mock catalog
  rows when compact static catalog metadata is already present.

## Result

The GitHub Pages app can render the first screen with fewer static JSON
requests, while ETF search still loads the verified static catalog when needed.

## Validation

- Repository tests verify fast/full static lab data do not request the full
  catalog or history index.
- Widget tests verify search can lazy-load the catalog when first-screen data
  omits it.
- Static data source labels remain truthful: static-public data is historical
  public data, not live intraday NAV.
