# 00631L lab v6.11 gap detail API

v6.11 adds a backend endpoint for inspecting ETF price-history gaps without
opening static JSON files manually.

## Endpoint

```text
GET /api/etf/history/gaps
```

Query parameters:

- `reason`: optional gap reason filter, for example `official_empty` or
  `source_error`.
- `limit`: number of returned rows, default `50`, maximum `500`.
- `fromCatalog`: when `true`, build the gap universe from the ETF catalog or
  catalog seed; otherwise use the saved ETF price-history index.

## Response

The response includes:

- `gapReasonCounts`
- `gapReasonSamples`
- `gapDetailCount`
- `items`
- `catalogRowCount` when `fromCatalog=true`

The endpoint is for maintenance and data verification. Only ETFs with verified
price-history rows are used by history, backtest, and comparison views.
