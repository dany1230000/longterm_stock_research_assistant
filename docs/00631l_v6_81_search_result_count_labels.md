# 00631L lab v6.81 search result count labels

v6.81 makes the left-top ETF search sheet result counts clearer.

## What changed

- The local result counters now use Chinese labels:
  - `目前結果 歷史可用`
  - `目前結果 未匯入歷史`
- The labels distinguish the current visible search result set from the full
  ETF database readiness summary above it.
- The underlying search, catalog, and history readiness logic is unchanged.

## Why

The search sheet already shows full ETF database readiness, for example
`歷史可用 231 / 347` and `缺口 116`. The smaller per-result chips still used
English internal terms such as `history-ready` and `catalog-only`, which could
look like another global data summary.

## Validation

- Widget coverage verifies the catalog-only search case displays the new
  result-count labels and no longer renders the old English chip text.
