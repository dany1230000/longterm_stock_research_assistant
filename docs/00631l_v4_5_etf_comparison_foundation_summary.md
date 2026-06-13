# 00631L lab v4.5 ETF comparison foundation summary

## Scope

v4.5 adds a first ETF comparison foundation using existing catalog snapshot fields. It does not add full ETF history, full multi-ETF backtesting, investment guidance, notifications, or automated trading.

## Completed

- Added an `ETF 比較基礎` section to the ETF page.
- The comparison table uses catalog rows already exposed through `EtfCatalog`.
- Compared fields include code, name, market price, estimated NAV, premium/discount, previous NAV, and data time.
- The UI clearly states that this is not a full performance comparison.
- Widget tests now cover the ETF comparison foundation section.

## Data Boundary

The comparison foundation only uses catalog snapshot fields. Long-term return, drawdown, and backtest comparisons require separate verified historical data for each ETF before they can be shown truthfully.

## Next Step

Add a multi-ETF historical data pipeline and only then enable full ETF performance comparison.
