# 00631L lab v8.8 ETF history source provenance

## Goal

Make ETF price-history provenance visible after the TPEx fallback added in v8.7.
The app should not imply that all ETF history rows come from TWSE when some rows
were filled by the official TPEx ETF daily-history endpoint.

## What changed

- Backend price-history status now includes `historySourceContractCounts`.
- Static export writes the same source-count metadata into `status.json`,
  `manifest.json`, `etf_price_history_index.json`, and each exported ETF
  history file.
- Flutter repositories parse the source counts in live proxy and static-public
  modes.
- The ETF data-completion view and selected ETF history card show concise
  `TWSE / TPEx` source labels.

## Source contracts

- `twse_stock_day_json`: TWSE official STOCK_DAY history rows.
- `tpex_etf_historical_daily_json`: TPEx official ETF historical daily rows.

The static wrapper contracts remain unchanged. They describe the exported file
format, while `historySourceContractCounts` describes the row-level source mix.

## User-facing rule

Source labels are data provenance only. They do not change comparison or
backtest logic, and they are not investment guidance.
