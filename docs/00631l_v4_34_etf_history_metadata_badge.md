# 00631L lab v4.34 ETF history metadata badge

v4.34 makes ETF search readiness more specific.

## What Changed

- ETF search result rows now show a concise price-history metadata badge when available.
- The badge format is `<coverageTier> · <rowCount> 筆`, for example `recent · 12 筆`.
- ETF catalog rows use the same metadata badge when the catalog item carries history metadata.

## Why

The selector should not only say that an ETF is ready. It should also expose how much verified history is attached to that symbol, so users can quickly distinguish long-term history from shorter recent coverage.

## Scope

- UI display only.
- Uses existing static/proxy metadata.
- Does not create new ETF live holdings, notifications, or investment guidance.
