# 00631L Lab v9.12 Compact Overview Readiness

## Scope

This release tightens the mobile overview first screen.

- The quote card now includes a compact readiness strip for holdings, intraday NAV, price history, and backend mode.
- The old standalone overview data card is removed from the first screen.
- The price chart appears sooner after the quote card.
- Source labels remain explicit; fallback or static data is not presented as live.

## User Impact

On a phone, the overview now prioritizes:

1. ETF code and quote.
2. Premium/discount status.
3. Holdings / intraday / history / backend readiness.
4. One-year chart.

Advanced diagnostics remain under the existing advanced section.

## Limits

- No TX live integration was added.
- No broader ETF universe expansion was added in this release.
- No investment instruction wording or automated trading behavior was added.
