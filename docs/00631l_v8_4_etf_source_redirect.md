# 00631L lab v8.4 ETF source redirect handling

v8.4 reduces false `source_error` classifications in ETF price-history imports.

## What changed

- The backend fetcher now treats official HTTP 3xx responses as redirects and
  retries through the existing redirect-capable curl fallback.
- Non-redirect HTTP errors still fail clearly.
- Official TWSE empty responses still stay unavailable. They are not converted
  into fake history rows.

## Why it matters

Some ETF symbols can receive a TWSE `HTTP 307` response before the final
STOCK_DAY JSON payload. Before v8.4, that redirect could be recorded as a
`source_error`. After v8.4, the importer can reach the final official payload.

If the final official payload says there is no matching data, the app keeps the
gap reason as official empty data.

## Data boundary

This release only fixes transport handling for official TWSE sources. It does
not add third-party data and does not infer missing historical prices.
