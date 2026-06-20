# 00631L v4.18 ETF search readiness summary

Date: 2026-06-20

## Scope

This release improves the top-left ETF search sheet so users can tell whether an ETF has imported, verifiable price history before switching context.

## Changes

- The search status row now shows `可用歷史` instead of an English-only ready count.
- ETF search result tiles show whether history/backtest data is available or whether the item is catalog-only.
- History-ready ETF tiles include a short caption that coverage and backtest details appear after switching.
- Catalog-only ETF tiles clearly say that only catalog fields are available until verified price history is imported.
- Widget tests cover both history-ready and catalog-only search result states.

## Notes

This does not add new ETF live holdings. 00631L remains the only ETF with full official holdings and intraday NAV integration. Other ETFs use catalog and imported price-history data when available.
