# 00631L lab v6.6 ETF library status

v6.6 carries the public ETF history universe metrics into the generated static
data, backend operations status, Flutter repositories, and app status UI.

## What Changed

- Static export now writes `etfPriceHistoryOutOfCatalogCount`.
- Backend `/api/etf/00631l/operations/status` includes
  `etfPriceHistory.outOfCatalogCount`.
- Flutter operations status reads the value from live proxy and static public
  data.
- The app status detail shows retained ETF history rows separately from current
  catalog rows.
- Classified missing histories no longer trigger the same program action as
  unclassified gaps.

## Meaning

- `not_saved` is the maintenance signal for an unclassified gap.
- `official_empty` and `source_error` are classified reasons.
- `outOfCatalogCount` means a retained history row is not in the current ETF
  catalog snapshot. It is evidence, not a ready-data failure by itself.

## Boundary

This is a data-status and UX clarity release. It does not create histories for
officially unavailable sources, does not change price calculations, and does not
add investment guidance.
