# 00631L v4.13 intraday time and TX quote fix

Date: 2026-06-17

## Scope

This patch fixes two data-quality issues in the 00631L research room:

- Home quote time now displays Taipei time with the date when the source data is not from the current Taipei calendar day.
- TAIFEX TX live quote no longer uses the legacy `TXF-P` stream as the futures price source.

## TX quote correction

The backend now resolves the active month-coded TAIFEX TX futures symbol automatically. For example, the 2026/06 contract resolves to `TXFF6-F`; after the third-Wednesday rollover cutoff it resolves to the next month, such as `TXFG6-F`.

Legacy `TAIFEX_TX_FUTURES_SYMBOL=TXF-P` is treated as `auto`, because `TXF-P` can omit the futures last-price field and should not be shown as a successful live TX futures quote.

## UI changes

- The overview TX card shows the contract month, resolved TX symbol, price, and basis.
- The data status section shows the same contract month and symbol.
- If TAIFEX does not provide a valid last price, the app keeps the source as unavailable/stale/cached/mock instead of presenting fallback data as official.

## Validation

- Backend unit tests cover TX month-symbol resolution before and after the expiry rollover cutoff.
- Proxy repository tests verify `txSymbol` mapping.
- Live smoke during the regular session returned official TX quote data with a fresh TAIFEX data time.

## Boundaries

This patch does not expand the product beyond the ETF research room, does not add alerts, does not add broker integration, and does not provide investment guidance.
