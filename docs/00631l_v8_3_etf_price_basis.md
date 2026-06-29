# 00631L lab v8.3 ETF price basis metadata

v8.3 makes ETF search data quality clearer before the user switches symbols.

## What changed

- Static export now enriches catalog rows with price-history basis metadata:
  - `priceHistoryPriceField`
  - `priceHistoryAdjustmentMethod`
  - `priceHistoryAdjustmentEventCount`
- The top-left ETF search sheet and catalog list can show compact basis badges:
  - adjusted price
  - adjusted price with known split events
  - close price
- The badge is only shown for ETFs with usable imported history.

## Why it matters

Some ETF histories use split-adjusted prices for charts, comparison, and
backtest context. Others have no known split event and use close price. The app
now exposes that distinction earlier in the symbol selection flow.

## Boundary

This does not infer missing corporate actions. Known split events are only used
when the data pipeline has explicit metadata for that ETF code.
