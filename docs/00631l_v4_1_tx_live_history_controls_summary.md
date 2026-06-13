# 00631L v4.1 TX live and history controls summary

## Completed

- History/backtest now opens with a trailing one-year default range.
- History/backtest date range can be adjusted with start/end date controls and quick range chips.
- The light/dark toggle now changes the 00631L market UI palette, not only the outer Flutter theme mode.
- Backend adds TAIFEX TX quote support at `GET /api/etf/00631l/tx-quote`.
- Operations/status includes TX quote metadata and a TWSE ETF catalog status.
- Frontend overview and data-status sections show TAIFEX TX quote status separately from daily Yuanta holdings.
- Backend adds a TWSE all-ETF catalog importer:
  - `GET /api/etf/catalog`
  - `GET /api/etf/catalog/status`
  - `POST /api/etf/catalog/import`
  - `scripts\00631l_import_etf_catalog.cmd`

## Data behavior

- Yuanta ratio holdings remain an official daily snapshot.
- TWSE intraday NAV remains the fast market price, estimated NAV, premium/discount, and data-time source.
- TAIFEX TX quote uses `sourceContract: taifex_sockjs_quote` and can be unavailable or stale outside active sessions.
- TWSE all-ETF catalog import normalizes `all_etf.txt` rows for future ETF-room expansion. It does not make this release an all-ETF product.
- Static-public history and backtest remain available without a live backend.

## Validation scope

- Parser and endpoint tests cover TAIFEX TX quote parsing and TWSE ETF catalog import.
- Frontend tests cover TX quote repository mapping, one-year history default, and real palette switching.
- Mock/fallback data stays clearly labeled and is not presented as official data.

## Still not included

- No TX futures trading workflow.
- No broader ETF research pages beyond the catalog foundation.
- No notifications.
- No automated trading.
- No investment guidance.
