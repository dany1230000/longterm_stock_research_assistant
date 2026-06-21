# 00631L lab v4.32 search readiness metadata

v4.32 tightens the ETF selector data contract.

## What Changed

- The top-left ETF search sheet now shows the ETF price-history ready count from operations/static status when that count is newer than the local fallback list.
- Static public catalog items are enriched from `etf_price_history_index.json`.
- Each `EtfCatalogItem` can carry price-history row count, coverage tier, coverage range, and source status.
- Search and catalog result tiles can mark an ETF as history/backtest ready from verified metadata instead of relying only on the old hard-coded representative list.

## Why

Static public data currently contains many ETF history files. The UI previously still looked like only the small representative basket was ready. This made the selector look under-loaded even when `scripts\00631l_export_static_data.cmd --status-only` reported more ETF histories.

## Scope

- This is a data-readiness UI and repository contract patch.
- It does not add new live holdings for other ETFs.
- It does not label static history as live intraday data.
- It does not add notifications, broker integration, or investment guidance.

## Validation

- Widget coverage checks that the selector uses operations status ready counts.
- Widget coverage checks that a catalog item with price-history metadata is marked ready even if it is not in the old representative list.
- Repository coverage checks static catalog enrichment from `etf_price_history_index.json`.
