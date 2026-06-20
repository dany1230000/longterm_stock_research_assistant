# 00631L v4.17 data correctness panel summary

Date: 2026-06-20

## Scope

This release makes price-history correctness easier to see from the overview page.

## Changes

- `EtfPriceHistoryCompletenessSummary` now reports whether history has `adjustedClose` and whether any row has a non-unit adjustment factor.
- The overview page now includes a compact `資料正確性` panel.
- The panel shows price field, split-adjustment status, coverage row count/range, and source status.
- Widget tests verify the panel appears on the first screen.
- Model tests verify split-adjusted histories expose adjusted-price and non-unit adjustment flags.

## Notes

00631L historical performance and backtest calculations use adjusted price fields when present. Static history, live intraday data, cached data, stale data, and fallback data remain separately labeled.
