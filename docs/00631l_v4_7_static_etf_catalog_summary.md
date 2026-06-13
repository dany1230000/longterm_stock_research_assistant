# 00631L lab v4.7 static ETF catalog summary

v4.7 imports the TWSE all-ETF catalog into the static-public data package.
The public GitHub Pages app can now load ETF catalog/search data without
waiting for a live backend.

## Completed

- Static export writes `etf_catalog.json` next to `price_history.json`,
  `performance.json`, `status.json`, and `manifest.json`.
- GitHub Pages workflow refreshes TWSE all-ETF catalog before Flutter build.
- A committed official catalog snapshot seed is available for short-lived
  network failures during static export.
- Static repository reads `etf_catalog.json` and exposes catalog row count,
  data time, status, and items to the app.
- Operations status in static mode includes ETF catalog row count and data time.

## Source Status

- Source: TWSE `https://mis.twse.com.tw/stock/data/all_etf.txt`
- Static contract: `twse_all_etf_catalog_static_public`
- Public mode label: `static_official`

The snapshot is a static official data export. It is not live intraday data.
Live intraday NAV and official 00631L holdings still require the backend proxy.

## Limits

- This release imports catalog snapshot fields only.
- Multi-ETF historical performance and multi-ETF backtest comparison still need
  separate verified historical data per ETF.
- 00631L remains the focused research room.
